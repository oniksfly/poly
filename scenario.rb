require_relative 'utils'

USER_EMAIL = 'uname'
USER_PASSWORD = 'upswd'

user_sign_in(email: USER_EMAIL, password: USER_PASSWORD)
users_list
sleep_seconds 31
users_list
teams_list
sleep_seconds 2
teams_list