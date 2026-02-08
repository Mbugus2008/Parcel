@echo off
echo Setting up SSH key authentication...
echo.
echo Please enter your password when prompted (you may need to enter it multiple times)
echo.

REM Step 1: Upload the key
echo Step 1: Uploading SSH key to server...
scp "%USERPROFILE%\.ssh\id_rsa.pub" Administrator@trimline.co.ke:~/uploaded_key.pub

REM Step 2: Setup on server
echo.
echo Step 2: Setting up key on server...
echo Please enter password again when prompted
ssh Administrator@trimline.co.ke "mkdir -p .ssh && cat uploaded_key.pub >> .ssh/authorized_keys && chmod 600 .ssh/authorized_keys && chmod 700 .ssh && rm uploaded_key.pub && echo SUCCESS"

echo.
echo Step 3: Testing passwordless connection...
ssh Administrator@trimline.co.ke "echo Passwordless SSH is working!"

echo.
echo Done!
pause
