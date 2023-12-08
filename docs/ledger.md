# Connect Ledger Nano S to your Zenon Wallet

Install the Zenon Ledger app on your Ledger Nano S to manage ZNN, QSR and ZTS tokens with the Zenon CLI. The Zenon Ledger app is developed and supported by the [{H}yperCore One](https://github.com/hypercore-one) team.

### 1. Before you start

- You've [initialized](https://support.ledgerwallet.com/hc/en-us/articles/360000613793) your Ledger Nano S.
- The latest firmware is [installed](https://support.ledgerwallet.com/hc/en-us/articles/360002731113).
- Ledger Live is [ready to use](https://support.ledgerwallet.com/hc/en-us/articles/360006395233).

### 2. Install the Zenon app

1. Open the Manager in Ledger Live.
2. Connect and unlock your Ledger Nano S.
3. If asked, allow the manager on your device by pressing the right button.
4. Find **Zenon** in the app catalog.
5. Press the **Install** button of the app.
   - An installation window appears.
   - Your device will display **Processing�**
   - The app installation is confirmed.

![nanos-znn-app](/docs/assets/screenshots/nanos-znn-app.png)

### **3. Connect device to your Zenon wallet**

- Open the Zenon application on your Ledger device, the screen will display "Zenon is ready".

![nanos-znn-app](/docs/assets/screenshots/nanos-znn-ready.png)

- The Zenon CLI is available Linux/MacOs/Windows as a downloadable binary from the [releases page][/releases].
- Install the Zenon CLI by extracting the archive to a location on your desktop device.
- Open a command prompt and change directory to the location of the Zenon CLI. For example: `cd ~/znn-cli`.

### **4. Use the Zenon wallet**

- Your address can be displayed with the following command: `znn-cli wallet.deriveAddresses 0 1 -k "Nano S"`. You can use it to receive ZTS tokens.
- To receive, execute the following command: `znn-cli receiveAll -k "Nano S" -u wss://my.hc1node.com:35998`.
- To send 10 ZNN to z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7, execute the following command: `znn-cli send z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7 10 ZNN -k "Nano S" -u wss://my.hc1node.com:35998`.
- Verify and confirm all transaction details on the ledger device.
- Press both buttons to sign the transaction.

### **5. Contact info**

- Support: Go to the #dev-community channel in our Discord: https://discord.gg/aEW2UZvs
- Name: [{H}yperCore One](https://github.com/hypercore-one)
- Legal Entity: NOM Labz LLC
- URL: [Zenon Network]http://zenon.network