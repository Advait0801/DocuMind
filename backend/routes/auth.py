from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timedelta, timezone

from models.database import get_db
from utils.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    ACCESS_TOKEN_EXPIRE_DAYS
)
from utils.schemas import UserRegister, UserLogin, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, db=Depends(get_db)):
    """Register a new user with username, email, and password."""
    # Check if username already exists
    existing_username = await db.users.find_one({"username": user_data.username})
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Check if email already exists
    existing_email = await db.users.find_one({"email": user_data.email})
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    hashed_password = get_password_hash(user_data.password)
    user_doc = {
        "username": user_data.username,
        "email": user_data.email,
        "hashed_password": hashed_password,
        "created_at": datetime.now(timezone.utc),
    }
    
    result = await db.users.insert_one(user_doc)
    user_id = str(result.inserted_id)
    
    # Generate tokens
    access_token = create_access_token(
        data={"sub": user_id, "email": user_data.email, "username": user_data.username},
        expires_delta=timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    )
    refresh_token = create_refresh_token(
        data={"sub": user_id, "email": user_data.email, "username": user_data.username}
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db=Depends(get_db)):
    """Login with username or email and password."""
    # Try to find user by username first, then by email
    user = await db.users.find_one(
        {
            "$or": [
                {"username": credentials.username_or_email},
                {"email": credentials.username_or_email},
            ]
        }
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password"
        )
    
    # Verify password
    if not verify_password(credentials.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password"
        )
    
    # Generate tokens
    access_token = create_access_token(
        data={"sub": str(user["_id"]), "email": user["email"], "username": user["username"]},
        expires_delta=timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    )
    refresh_token = create_refresh_token(
        data={"sub": str(user["_id"]), "email": user["email"], "username": user["username"]}
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )

