const http = await import('http');
import * as Nomad from './nomad.js'
// See https://github.com/octokit/webhooks for more details
import { Webhooks, createNodeMiddleware } from "@octokit/webhooks";

const serverPort = process.env.PORT || 3000
const ghWebhookSecret = process.env.GH_WEBHOOK_SECRET || "mysecret"
const webhooks = new Webhooks({
    secret: ghWebhookSecret,
});

// Only listen to the "workflow_job.queued" event
const eventName = "workflow_job.queued";
webhooks.on(eventName, ({ id, name, payload }) => {
    console.log(`${eventName} event received`);
    Nomad.dispatchJob(name, payload);
});

const middleware = createNodeMiddleware(webhooks, { path: "/" });
http.createServer(middleware).listen(serverPort);
