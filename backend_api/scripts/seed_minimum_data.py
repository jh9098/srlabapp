from app.db.session import SessionLocal
from app.services.seed import seed_minimum_data


def main() -> None:
    db = SessionLocal()
    try:
        seed_minimum_data(db)
        print("minimum seed data inserted or already exists")
    finally:
        db.close()


if __name__ == "__main__":
    main()
