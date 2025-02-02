import os
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
from functools import wraps
from datetime import datetime, timedelta
from bson import Binary

load_dotenv()
db_conn = os.getenv('DB_CONN')
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')

# Connect to MongoDB
client = MongoClient(db_conn)
db = client.serene_stream_db
users = db.users
mongo_test = db.mongo_test
clips = db.clips


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

    if not file.filename.lower().endswith('.m4a'):
        return jsonify({'message': 'Only M4A files are allowed'}), 400

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
            'content_type': 'audio/mpeg'
        }

        # Insert into MongoDB
        result = clips.insert_one(clip_document)

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
