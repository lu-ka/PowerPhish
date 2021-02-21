# PowerPhish
This powershell script opens a realistic looking window thats asking for your windows username and password. If the input is correct the loot is uploaded to a pastebin account. If the entered username or password is wrong the script will start again. This script was created with a BAD-USB / HID / Ducky attack in mind. 

## Kudos
This script is based on https://github.com/Dviros/CredsLeaker

# How to use
Edit this script to your needs. You can change the following variables:
- $timer is how many seconds the script waits after loading itself to memory before presenting the credential window.
- $forceLanguage is used to force the language and ignore the deteced system language. ($null = off, example = "en-US")
- $url sets the "connection" name which is displayed in the message.

You have to set the following variables in order for the script to upload loot to Pastebin.
- $u is your Pastebin username
- $p is your Pastebin password
- $k is your Pastebin API key (can be found at https://pastebin.com/doc_api)

After editing you can run the script with "powershell ./PowerPhish.ps1"
For some reason, this script doenst work when run directly from Powershell ISE or Visual Studio Code. (Help appreciated)

You can add more languages by declaring "$CaptionXX" and "$MessageXX" for your language and editing the switch case for "$language" with your WinSystemLocale.

# Legal
This code is provided for educational use only. If you engage in any illegal activity the author does not take any responsibility for it. By using this code you agree with these terms.