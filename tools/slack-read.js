#!/usr/bin/env node

// Slack Read-Only Tool
// Usage: node slack-read.js <command> [args]

const { WebClient } = require('@slack/web-api');
const fs = require('fs');
const path = require('path');

// Find token
function getToken() {
    const secretsDir = path.join(process.env.HOME, '.secrets');
    const userToken = path.join(secretsDir, 'slack_user_token');
    const botToken = path.join(secretsDir, 'slack_bot_token');

    if (fs.existsSync(userToken)) {
        return fs.readFileSync(userToken, 'utf8').trim();
    }
    if (fs.existsSync(botToken)) {
        return fs.readFileSync(botToken, 'utf8').trim();
    }
    console.error('No Slack token found in ~/.secrets/');
    console.error('Run the setup: ./scripts/run.sh');
    process.exit(1);
}

const client = new WebClient(getToken());

// Commands
const commands = {
    async channels() {
        const result = await client.conversations.list({ types: 'public_channel,private_channel' });
        for (const ch of result.channels) {
            const type = ch.is_private ? 'private' : 'public';
            console.log(`${ch.id}\t${ch.name}\t(${type})`);
        }
    },

    async dms() {
        const result = await client.conversations.list({ types: 'im,mpim' });
        for (const ch of result.channels) {
            const type = ch.is_mpim ? 'group-dm' : 'dm';
            console.log(`${ch.id}\t${ch.name || ch.user || 'unnamed'}\t(${type})`);
        }
    },

    async history(channelId, limit = 20) {
        if (!channelId) {
            console.error('Usage: slack-read.js history <channel_id> [limit]');
            process.exit(1);
        }
        const result = await client.conversations.history({
            channel: channelId,
            limit: parseInt(limit)
        });
        for (const msg of result.messages.reverse()) {
            const time = new Date(msg.ts * 1000).toISOString();
            const user = msg.user || 'unknown';
            console.log(`[${time}] ${user}: ${msg.text}`);
        }
    },

    async search(query, limit = 20) {
        if (!query) {
            console.error('Usage: slack-read.js search <query> [limit]');
            process.exit(1);
        }
        const result = await client.search.messages({
            query,
            count: parseInt(limit)
        });
        for (const match of result.messages.matches) {
            const time = new Date(match.ts * 1000).toISOString();
            const user = match.user || match.username || 'unknown';
            const channel = match.channel?.name || 'unknown';
            console.log(`[${time}] #${channel} ${user}: ${match.text}`);
            console.log('---');
        }
    },

    async users() {
        const result = await client.users.list();
        for (const user of result.members) {
            if (!user.deleted && !user.is_bot) {
                console.log(`${user.id}\t${user.name}\t${user.real_name || ''}`);
            }
        }
    },

    async info(channelId) {
        if (!channelId) {
            console.error('Usage: slack-read.js info <channel_id>');
            process.exit(1);
        }
        const result = await client.conversations.info({ channel: channelId });
        const ch = result.channel;
        console.log(`Name: ${ch.name}`);
        console.log(`ID: ${ch.id}`);
        console.log(`Type: ${ch.is_private ? 'private' : 'public'}`);
        console.log(`Members: ${ch.num_members || 'unknown'}`);
        console.log(`Topic: ${ch.topic?.value || 'none'}`);
        console.log(`Purpose: ${ch.purpose?.value || 'none'}`);
    },

    help() {
        console.log(`Slack Read-Only Tool

Commands:
  channels              List all channels (public & private)
  dms                   List DMs and group DMs
  history <id> [n]      Read last n messages from channel (default: 20)
  search <query> [n]    Search messages (default: 20 results)
  users                 List workspace users
  info <id>             Get channel info
  help                  Show this help
`);
    }
};

// Main
async function main() {
    const [,, command, ...args] = process.argv;

    if (!command || !commands[command]) {
        commands.help();
        process.exit(command ? 1 : 0);
    }

    try {
        await commands[command](...args);
    } catch (err) {
        console.error('Error:', err.message);
        process.exit(1);
    }
}

main();
