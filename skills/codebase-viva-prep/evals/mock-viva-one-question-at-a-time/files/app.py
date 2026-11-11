from flask import Flask, request, redirect, session, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from models import db, User, Booking

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///treks.db"
app.secret_key = "dev"
db.init_app(app)

@app.route("/register", methods=["POST"])
def register():
    u = User(email=request.form["email"], pw_hash=generate_password_hash(request.form["password"]), role="user")
    db.session.add(u); db.session.commit()
    return redirect("/login")

@app.route("/login", methods=["POST"])
def login():
    u = User.query.filter_by(email=request.form["email"]).first()
    if u and check_password_hash(u.pw_hash, request.form["password"]):
        session["uid"] = u.id; session["role"] = u.role
        return redirect("/treks")
    return "invalid", 401

@app.route("/book/<int:trek_id>", methods=["POST"])
def book(trek_id):
    if "uid" not in session:
        return redirect("/login")
    taken = Booking.query.filter_by(trek_id=trek_id).count()
    if taken >= 20:
        return "full", 409
    db.session.add(Booking(user_id=session["uid"], trek_id=trek_id)); db.session.commit()
    return redirect("/my-bookings")

@app.route("/admin/delete/<int:user_id>", methods=["POST"])
def delete_user(user_id):
    if "uid" not in session:
        return redirect("/login")
    User.query.filter_by(id=user_id).delete(); db.session.commit()
    return "deleted"
