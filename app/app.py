from flask import Flask, render_template, request, redirect
from db import get_connection

app = Flask(__name__)


@app.route("/")
def home():
    return render_template("home.html")


@app.route("/booking")
def booking():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT c.id, c.name, c.instructor, c.class_time, c.capacity,
                   COUNT(b.id) AS booked_count
            FROM classes c
            LEFT JOIN bookings b ON b.class_id = c.id
            GROUP BY c.id, c.name, c.instructor, c.class_time, c.capacity
            ORDER BY c.class_time
        """)
        classes = cursor.fetchall()
        return render_template("booking.html", classes=classes)
    finally:
        conn.close()


@app.route("/book/<int:class_id>", methods=["POST"])
def book(class_id):
    name = request.form["name"]
    email = request.form["email"]

    conn = get_connection()
    try:
        cursor = conn.cursor()

        # Check capacity before booking
        cursor.execute("SELECT capacity FROM classes WHERE id = %s", (class_id,))
        class_info = cursor.fetchone()
        if not class_info:
            return "Class not found", 404

        cursor.execute("SELECT COUNT(*) AS count FROM bookings WHERE class_id = %s", (class_id,))
        current_bookings = cursor.fetchone()["count"]

        if current_bookings >= class_info["capacity"]:
            return render_template("full.html")

        # Find or create the user
        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()
        if user:
            user_id = user["id"]
        else:
            cursor.execute("INSERT INTO users (name, email) VALUES (%s, %s)", (name, email))
            conn.commit()
            user_id = cursor.lastrowid

                    # Check for an existing booking (same user, same class)
        cursor.execute(
            "SELECT id FROM bookings WHERE user_id = %s AND class_id = %s",
            (user_id, class_id)
        )
        existing_booking = cursor.fetchone()
        if existing_booking:
            cursor.execute("SELECT * FROM classes WHERE id = %s", (class_id,))
            booked_class = cursor.fetchone()
            return render_template("already_booked.html", name=name, booked_class=booked_class)

        # Book the class
        cursor.execute("INSERT INTO bookings (user_id, class_id) VALUES (%s, %s)", (user_id, class_id))
        conn.commit()

        # Book the class
        cursor.execute("INSERT INTO bookings (user_id, class_id) VALUES (%s, %s)", (user_id, class_id))
        conn.commit()

        # Get class details for the confirmation page
        cursor.execute("SELECT * FROM classes WHERE id = %s", (class_id,))
        booked_class = cursor.fetchone()

        return render_template("confirmation.html", name=name, booked_class=booked_class)
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True, threaded=True)
