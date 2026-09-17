from flask import Flask, render_template, request, redirect
from db import get_connection

app = Flask(__name__)

@app.route("/")
def home():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM classes ORDER BY class_time")
        classes = cursor.fetchall()
        return render_template("home.html", classes=classes)
    finally:
        conn.close()

@app.route("/book/<int:class_id>", methods=["POST"])
def book(class_id):
    name = request.form["name"]
    email = request.form["email"]

    conn = get_connection()
    try:
        cursor = conn.cursor()

        # Find or create the user
        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()
        if user:
            user_id = user["id"]
        else:
            cursor.execute("INSERT INTO users (name, email) VALUES (%s, %s)", (name, email))
            conn.commit()
            user_id = cursor.lastrowid

        # Book the class
        cursor.execute("INSERT INTO bookings (user_id, class_id) VALUES (%s, %s)", (user_id, class_id))
        conn.commit()

        return redirect("/")
    finally:
        conn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)