import got from "got";

const dispatchJob = async function(name, payload) {
    const nomadHost = process.env.NOMAD_HOST || "http://127.0.0.1"
    const nomadToken = process.env.NOMAD_TOKEN || ""
    const nomadJobId = process.env.NOMAD_JOB_ID || ""

    // only target events with "self-hosted" label
    const triggerConditions = (
        payload.workflow_job.labels.length > 0 &&
        payload.workflow_job.labels[0] === 'self-hosted'
    );
    if (!triggerConditions) return Promise.resolve();

    const data = await got.post(`${nomadHost}/v1/job/${nomadJobId}/dispatch`, {
        json: {
            'Meta': {
                'GH_REPO_URL': payload.repository.html_url,
            },
        },
        headers: {
            'X-Nomad-Token': nomadToken
        }
    }).json();
    console.log(`Job ID: ${nomadJobId} has been dispatched.`)
    console.log(data)

    return Promise.resolve()
}

export { dispatchJob };
