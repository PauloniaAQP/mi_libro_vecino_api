import firebase_admin
from firebase_admin import auth
from firebase_admin import credentials

EMAIL = 'admin@test.com'
PASSWORD = '123456789'

cred = credentials.Certificate("credentials.json") # get address for the credential's file of the project
firebase_admin.initialize_app(cred)

def _createAdminUser():
    user = auth.create_user(
        email=EMAIL,
        password=PASSWORD,
    )
    auth.set_custom_user_claims(user.uid, {
        'isAdmin': True
    })
    print("DONE")

def _verifyClaims(userID):
    user = auth.get_user(userID)
    print(user.custom_claims)


_createAdminUser()

