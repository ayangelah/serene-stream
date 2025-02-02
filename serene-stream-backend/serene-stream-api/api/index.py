import os
import io
from dotenv import load_dotenv
from flask import Flask, request, jsonify, send_file
import requests
from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
from functools import wraps
from datetime import datetime, timedelta
from bson import Binary
from .AudioProcessor import AudioProcessor
from http.cookies import SimpleCookie

load_dotenv()
db_conn = os.getenv('DB_CONN')
suno_cookie = os.getenv('SUNO_COOKIE')
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')

# Connect to MongoDB
client = MongoClient(db_conn)
db = client.serene_stream_db
users = db.users
mongo_test = db.mongo_test
clips = db.clips
tracks = db.tracks
generations = db.generations
suno_files = db.suno_files


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')

        if not token:
            return jsonify({'message': 'Token is missing'}), 401

        try:
            token = token.split(' ')[1]  # Remove 'Bearer ' prefix
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = users.find_one({'username': data['username']})
            if not current_user:
                return jsonify({'message': 'Invalid token'}), 401
        except:
            return jsonify({'message': 'Invalid token'}), 401

        return f(current_user, *args, **kwargs)

    return decorated


@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'message': 'Missing required fields'}), 400

    # Check if user already exists
    if users.find_one({'username': data['username']}):
        return jsonify({'message': 'Username already exists'}), 400

    # Generate password hash with salt
    hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')

    # Create new user
    new_user = {
        'username': data['username'],
        'password': hashed_password,
        'created_at': datetime.utcnow()
    }

    users.insert_one(new_user)

    return jsonify({'message': 'User created successfully'}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'message': 'Missing required fields'}), 400

    user = users.find_one({'username': data['username']})

    if not user:
        # Create a new user
        # Generate password hash with salt
        hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')

        # Create new user
        new_user = {
            'username': data['username'],
            'password': hashed_password,
            'created_at': datetime.utcnow()
        }

        users.insert_one(new_user)
    elif not check_password_hash(user['password'], data['password']):
        return jsonify({'message': 'Invalid username or password'}), 401

    # Generate JWT token
    token = jwt.encode({
        'username': user['username'],
        'exp': datetime.utcnow() + timedelta(hours=24)
    }, app.config['SECRET_KEY'])

    return jsonify({'token': token})


@app.route('/')
@token_required
def home(current_user):
    # Get the first document from the collection
    document = mongo_test.find_one()
    if document and 'testField' in document:
        return document['testField']
    return 'No data found'


@app.route('/about')
def about():
    return 'About'


@app.route('/clips', methods=['POST'])
@token_required
def upload_clip(current_user):
    if 'file' not in request.files:
        return jsonify({'message': 'No file part'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'message': 'No selected file'}), 400

    if not file.filename.lower().endswith('.flac'):
        return jsonify({'message': 'Only FLAC files are allowed'}), 400

    try:
        # Read the file content
        file_content = file.read()

        # Create audio file document
        clip_document = {
            'filename': file.filename,
            'content': Binary(file_content),  # Store file as binary data
            'user_id': current_user['_id'],
            'username': current_user['username'],
            'upload_date': datetime.utcnow(),
            'file_size': len(file_content),
            'content_type': 'audio/flac'
        }

        # Insert into MongoDB
        result = tracks.insert_one(clip_document)

        return jsonify({
            'message': 'File uploaded successfully',
            'file_id': str(result.inserted_id),
            'filename': file.filename
        }), 201

    except Exception as e:
        return jsonify({'message': f'Error uploading file: {str(e)}'}), 500


@app.route('/clips', methods=['GET'])
@token_required
def get_user_clips(current_user):
    # Get all files uploaded by the current user
    user_files = clips.find(
        {'user_id': current_user['_id']},
        {'content': 0}  # Exclude the file content from the results
    )

    files_list = [{
        'file_id': str(file['_id']),
        'filename': file['filename'],
        'upload_date': file['upload_date'].isoformat(),
        'file_size': file['file_size']
    } for file in user_files]

    return jsonify(files_list)


@app.route('/generateResult/<generation_key>', methods=['GET'])
@token_required
def generation_result_combined_clips(current_user, generation_key):
    generation = generations.find_one({
        'generation_key': generation_key,
        'user_id': current_user['_id']
    })

    suno_file = suno_files.find_one({
        'generation_key': generation_key,
        'user_id': current_user['_id']
    })

    if not generation:
        return jsonify({'message': 'Generation not found or unauthorized'}), 404

    if not suno_file:
        return jsonify({'message': 'Suno file not found or unauthorized'}), 404

    if not generation['ready']:
        return jsonify({'message': 'Generation not ready'}), 500

    filenames = generation['filenames']

    if not isinstance(filenames, list):
        return jsonify({'message': 'Filenames must be provided as an array'}), 400

    try:
        # Fetch all audio files that belong to the user
        audio_files = []
        for filename in filenames:
            file_doc = clips.find_one({
                'filename': filename,
                'user_id': current_user['_id']
            })

            if not file_doc:
                return jsonify({
                    'message': f'File not found or unauthorized: {filename}'
                }), 404

            file_wav_bytes = AudioProcessor.flac_to_wav(file_doc['content'])
            audio_files.append((file_wav_bytes, 'file.wav'))

        suno_file_mp3_bytes = suno_file['content']
        suno_file_wav_bytes = AudioProcessor.mp3_to_wav(suno_file_mp3_bytes)
        audio_files.append((suno_file_wav_bytes, 'suno_file_in.wav'))

        # Process and combine the audio files
        processor = AudioProcessor()
        combined_audio = processor.combine_audio_files(audio_files)
        combined_audio_mp3 = processor.wav_to_mp3(combined_audio)

        # save to MongoDB
        # Create audio file document
        track_document = {
            'user_id': current_user['_id'],
            'title': generation['title'],
            'content': Binary(combined_audio_mp3),  # Store file as binary data
        }

        try:
            # Insert into MongoDB
            result = tracks.insert_one(track_document)
            print(f"Track inserted with ID: {result.inserted_id}")
        except Exception as e:
            print(f"Error inserting track: {str(e)}")

        # Return the processed audio file
        return send_file(
            io.BytesIO(combined_audio_mp3),
            mimetype='audio/mpeg',
            as_attachment=True,
            download_name=generation['title'] + '.mp3'
        )

    except Exception as e:
        return jsonify({'message': f'Error generating audio: {str(e)}'}), 500


@app.route('/generate', methods=['POST'])
@token_required
def generate(current_user):
    data = request.get_json()

    if not data or 'filenames' not in data or 'prompt' not in data or 'title' not in data:
        return jsonify({'message': 'Missing required fields'}), 400

    try:
        for filename in data['filenames']:
            file_doc = clips.find_one({
                'filename': filename,
                'user_id': current_user['_id']
            })

            if not file_doc:
                return jsonify({
                    'message': f'File not found or unauthorized: {filename}'
                }), 404

        # Get generation key from external service
        cookie = SimpleCookie()
        cookie.load(suno_cookie)

        response = requests.post('https://suno-api-psi-bice.vercel.app/api/generate',
                                 json={
                                     'prompt': data['prompt'],
                                     'make_instrumental': True,
                                     'wait_audio': False
                                 },
                                 cookies={key: morsel.value for key, morsel in cookie.items()})

        generation_key = response.json()[0]['id']

        # Create generation document
        generation_doc = {
            'generation_key': generation_key,
            'title': data['title'],
            'filenames': data['filenames'],
            'ready': False,
            'user_id': current_user['_id'],
            'username': current_user['username']
        }

        # Insert into MongoDB
        generations.insert_one(generation_doc)

        return jsonify({
            'generation_key': generation_key
        })

    except requests.RequestException as e:
        return jsonify({'message': f'Error fetching generation key: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': f'Error creating generation: {str(e)}'}), 500


@app.route('/generateStatus/<generation_key>', methods=['GET'])
@token_required
def get_generation_status(current_user, generation_key):
    try:
        generation = generations.find_one({
            'generation_key': generation_key,
            'user_id': current_user['_id']
        })

        if not generation:
            return jsonify({'message': 'Generation not found or unauthorized'}), 404

        if not generation['ready']:
            response = requests.get('https://suno-api-psi-bice.vercel.app/api/get?ids=' + generation_key,
                                    headers={"Cookie": suno_cookie})

            try:
                audio_url = response.json()[0]['audio_url']
            except Exception:
                pass
            else:
                response = requests.get(audio_url, stream=True)
                if response.status_code == 200:
                    mp3_bytes = response.content
                else:
                    raise Exception(f"Failed to download: {response.status_code}")

                suno_file_document = {
                    'generation_key': generation_key,
                    'user_id': current_user['_id'],
                    'content': Binary(mp3_bytes)
                }

                suno_files.insert_one(suno_file_document)

                generation['ready'] = True

                generations.update_one({
                    'generation_key': generation_key,
                    'user_id': current_user['_id']
                },
                {'$set':
                     {'ready': True}
                 })

        return jsonify({
            'ready': generation['ready']
        })

    except Exception as e:
        return jsonify({'message': f'Error fetching generation status: {str(e)}'}), 500
