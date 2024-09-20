#!/bin/bash
log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}
print_green() {
    echo -e "\e[32m$1\e[0m"
}
curl -s https://data.zamzasalim.xyz/file/uploads/asclogo.sh | bash
sleep 5

echo "Dawn Validator"
sleep 2

SERVICE_NAME=dawnbot
SCRIPT_PATH=/usr/local/bin/main.py   # Changed to a more macOS-friendly script path
WORKING_DIR=$HOME/DawnBot             # Changed to use the user's home directory

REQUIREMENTS_PATH=$WORKING_DIR/requirements.txt
SESSION_SCRIPT=$WORKING_DIR/sesi.py

DOWNLOAD_URL=https://data.winnode.xyz/file/uploads/DawnBot.rar
RAR_FILE=$HOME/DawnBot.rar             # Changed to use the user's home directory
EXTRACT_DIR=$HOME/DawnBot              # Changed to use the user's home directory

CONFIG_FILE=$WORKING_DIR/config.json

mkdir -p $EXTRACT_DIR

echo "Downloading $DOWNLOAD_URL..."
curl -o $RAR_FILE $DOWNLOAD_URL

if ! command -v unrar &> /dev/null; then
    echo "Unrar not found. Installing unrar via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install unrar
fi

echo "Extracting $RAR_FILE to $EXTRACT_DIR..."
unrar x $RAR_FILE $EXTRACT_DIR/

echo "Removing $RAR_FILE..."
rm $RAR_FILE

if ! command -v python3 &> /dev/null; then
    echo "Python 3 not found. Installing Python 3 via Homebrew..."
    brew install python
else
    echo "Python 3 is already installed."
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq via Homebrew..."
    brew install jq
fi

if [ -f "$REQUIREMENTS_PATH" ]; then
    echo "Installing dependencies from $REQUIREMENTS_PATH..."
    python3 -m pip install --upgrade pip
    python3 -m pip install -r $REQUIREMENTS_PATH
else
    echo "File $REQUIREMENTS_PATH not found. Skipping dependency installation."
fi

if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    read -p "Use Telegram (true/false): " USE_TELEGRAM
    read -p "Use Proxy (true/false): " USE_PROXY

    CONFIG_JSON=$(jq -n \
        --arg useTelegram "$USE_TELEGRAM" \
        --arg useProxy "$USE_PROXY" \
        '{telegram_bot_token: "", telegram_chat_id: "", use_telegram: ($useTelegram | test("true")), use_proxy: ($useProxy | test("true")), poll_interval: 300, accounts: []}'
    )

    if [ "$USE_TELEGRAM" == "true" ]; then
        read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
        read -p "Enter Telegram Chat ID: " TELEGRAM_CHAT_ID

        CONFIG_JSON=$(echo "$CONFIG_JSON" | jq --arg botToken "$TELEGRAM_BOT_TOKEN" --arg chatId "$TELEGRAM_CHAT_ID" \
            '.telegram_bot_token = $botToken | .telegram_chat_id = $chatId'
        )
    fi

    read -p "Enter the number of accounts to add (minimum 1): " NUM_ACCOUNTS

    while [ "$NUM_ACCOUNTS" -lt 1 ]; do
        echo "Number of accounts must be at least 1. Please enter a valid number."
        read -p "Enter the number of accounts to add (minimum 1): " NUM_ACCOUNTS
    done

    for (( i=1; i<=$NUM_ACCOUNTS; i++ )); do
        echo "Enter details for account $i:"
        read -p "Email: " EMAIL
        read -p "Token: " TOKEN

        CONFIG_JSON=$(echo "$CONFIG_JSON" | jq --arg email "$EMAIL" --arg token "$TOKEN" \
            '.accounts += [{"email": $email, "token": $token}]'
        )
    done

    echo "$CONFIG_JSON" > "$CONFIG_FILE"
    
    echo "Config file $CONFIG_FILE has been created and populated"
