import os
from datetime import datetime, timezone

import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request
from flask_cors import CORS


app = Flask(__name__)
CORS(app)


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres"),
        port=os.getenv("DB_PORT", "5432"),
        database=os.getenv("DB_NAME", "tododb"),
        user=os.getenv("DB_USER", "todo"),
        password=os.getenv("DB_PASSWORD", "todo_password"),
    )


def initialize_database():
    connection = get_db_connection()

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS todos (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                completed BOOLEAN NOT NULL DEFAULT FALSE,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

        connection.commit()
        cursor.close()

    finally:
        connection.close()


@app.route("/api/health", methods=["GET"])
def health():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()

        cursor.close()
        connection.close()

        return jsonify({
            "status": "healthy",
            "database": "connected"
        }), 200

    except Exception as error:
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(error)
        }), 500


@app.route("/api/todos", methods=["GET"])
def get_todos():
    connection = get_db_connection()

    try:
        cursor = connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute(
            """
            SELECT
                id,
                title,
                description,
                completed,
                created_at
            FROM todos
            ORDER BY created_at DESC
            """
        )

        todos = cursor.fetchall()

        for todo in todos:
            if todo["created_at"]:
                todo["created_at"] = todo["created_at"].isoformat()

        cursor.close()

        return jsonify(todos), 200

    finally:
        connection.close()


@app.route("/api/todos", methods=["POST"])
def create_todo():
    data = request.get_json()

    if not data:
        return jsonify({
            "error": "Request body is required"
        }), 400

    title = data.get("title", "").strip()
    description = data.get("description", "").strip()

    if not title:
        return jsonify({
            "error": "Todo title is required"
        }), 400

    if len(title) > 255:
        return jsonify({
            "error": "Todo title must be less than 255 characters"
        }), 400

    connection = get_db_connection()

    try:
        cursor = connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute(
            """
            INSERT INTO todos (title, description)
            VALUES (%s, %s)
            RETURNING id, title, description, completed, created_at
            """,
            (title, description)
        )

        todo = cursor.fetchone()

        connection.commit()
        cursor.close()

        todo["created_at"] = todo["created_at"].isoformat()

        return jsonify(todo), 201

    finally:
        connection.close()


@app.route("/api/todos/<int:todo_id>", methods=["PUT"])
def update_todo(todo_id):
    data = request.get_json()

    if not data or "completed" not in data:
        return jsonify({
            "error": "completed field is required"
        }), 400

    completed = bool(data["completed"])

    connection = get_db_connection()

    try:
        cursor = connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute(
            """
            UPDATE todos
            SET completed = %s
            WHERE id = %s
            RETURNING id, title, description, completed, created_at
            """,
            (completed, todo_id)
        )

        todo = cursor.fetchone()

        if not todo:
            connection.rollback()
            return jsonify({
                "error": "Todo not found"
            }), 404

        connection.commit()
        cursor.close()

        todo["created_at"] = todo["created_at"].isoformat()

        return jsonify(todo), 200

    finally:
        connection.close()


@app.route("/api/todos/<int:todo_id>", methods=["DELETE"])
def delete_todo(todo_id):
    connection = get_db_connection()

    try:
        cursor = connection.cursor()

        cursor.execute(
            "DELETE FROM todos WHERE id = %s RETURNING id",
            (todo_id,)
        )

        deleted = cursor.fetchone()

        if not deleted:
            connection.rollback()
            return jsonify({
                "error": "Todo not found"
            }), 404

        connection.commit()
        cursor.close()

        return jsonify({
            "message": "Todo deleted successfully"
        }), 200

    finally:
        connection.close()


initialize_database()

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )