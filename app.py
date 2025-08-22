"""Basic example Flask application."""

from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    """Example index page."""
    return f'<h1>Cloudsmith Example Flask App</h1>'


if __name__ == "__main__":
    app.run(debug=True)
