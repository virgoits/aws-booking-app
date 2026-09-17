import pymysql
import os

def get_connection():
    return pymysql.connect(
        host=os.environ.get("DB_HOST"),
        user=os.environ.get("DB_USER", "admin"),
        password=os.environ.get("DB_PASSWORD"),
        database=os.environ.get("DB_NAME", "bookingapp"),
        cursorclass=pymysql.cursors.DictCursor
    )