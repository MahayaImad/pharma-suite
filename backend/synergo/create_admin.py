
import asyncio
from app.core.database import async_session_factory
from app.core.security import get_password_hash
from app.models.user import User
from sqlalchemy import insert

async def create_admin():
  async with async_session_factory() as db:
      await db.execute(insert(User).values(
          username='admin',
          hashed_password=get_password_hash('admin'),
          is_active=True,
          role='admin'
      ))
      await db.commit()
      print('Admin créé : admin / admin')

asyncio.run(create_admin())
