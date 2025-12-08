from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timedelta, timezone

from models.database import get_db
from utils.auth import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    decode_token,
    revoke_token,
    is_token_revoked,
    ACCESS_TOKEN_EXPIRE_DAYS,
    oauth2_scheme
)
from utils.schemas import UserRegister, UserLogin, TokenResponse, RefreshTokenRequest

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


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: RefreshTokenRequest, db=Depends(get_db)):
    """Refresh access token using a valid refresh token."""
    try:
        # Ensure refresh token hasn't been revoked
        if await is_token_revoked(request.refresh_token, db):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has been revoked. Please log in again."
            )
        
        # Decode and validate refresh token
        payload = decode_refresh_token(request.refresh_token)
        
        # Extract user info from token
        user_id = payload.get("sub")
        email = payload.get("email")
        username = payload.get("username")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        # Generate new access token
        access_token = create_access_token(
            data={"sub": user_id, "email": email, "username": username},
            expires_delta=timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
        )
        
        # Optionally generate a new refresh token (refresh token rotation)
        # For simplicity, we'll return the same refresh token
        # In production, you might want to rotate refresh tokens
        refresh_token = create_refresh_token(
            data={"sub": user_id, "email": email, "username": username}
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not refresh token: {str(e)}"
    )


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    request: RefreshTokenRequest,
    token: str = Depends(oauth2_scheme),
    db=Depends(get_db)
):
    """
    Revoke both the current access token and provided refresh token.
    Clients should discard local tokens after this call.
    """
    # Validate access token and ensure it's not already revoked
    decode_token(token)
    if await is_token_revoked(token, db):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has already been revoked."
        )
    
    # Revoke access token
    await revoke_token(token, db)
    
    # Revoke refresh token (if valid)
    decode_refresh_token(request.refresh_token)
    await revoke_token(request.refresh_token, db)
    
    return {"message": "Successfully logged out"}

