Use `~/tools/slack-read.js` to read Slack data:

```bash
# List channels
node ~/tools/slack-read.js channels

# List DMs
node ~/tools/slack-read.js dms

# Read channel history (last 20 messages)
node ~/tools/slack-read.js history <channel_id>
node ~/tools/slack-read.js history <channel_id> 50  # last 50

# Search messages
node ~/tools/slack-read.js search "keyword"
node ~/tools/slack-read.js search "from:@user in:#channel"

# List users
node ~/tools/slack-read.js users

# Get channel info
node ~/tools/slack-read.js info <channel_id>
```

- This is read-only - you cannot send messages or modify anything
- Slack token is stored in `~/.secrets/`
- All execution happens in this container - no host access
