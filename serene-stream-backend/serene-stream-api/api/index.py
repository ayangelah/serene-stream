import os
from dotenv import load_dotenv
from flask import Flask
from pymongo import MongoClient

load_dotenv()
db_conn = os.getenv('DB_CONN')
app = Flask(__name__)

# Connect to MongoDB
client = MongoClient(db_conn)
db = client.serene_stream_db
collection = db.mongo_test

@app.route('/')
def home():
    # Get the first document from the collection
    document = collection.find_one()
    if document and 'testField' in document:
        return document['testField']
    return 'No data found'

@app.route('/about')
def about():
    return 'About'