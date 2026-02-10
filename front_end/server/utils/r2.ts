
import { S3Client } from '@aws-sdk/client-s3'

let _r2Client: S3Client | null = null

export const useR2Client = () => {
    if (_r2Client) return _r2Client

    const config = useRuntimeConfig()

    // Ensure keys are present
    if (!process.env.R2_ACCESS_KEY_ID || !process.env.R2_SECRET_ACCESS_KEY || !process.env.R2_ENDPOINT) {
        throw new Error('R2 Credentials missing in .env')
    }

    _r2Client = new S3Client({
        region: 'auto',
        endpoint: process.env.R2_ENDPOINT,
        credentials: {
            accessKeyId: process.env.R2_ACCESS_KEY_ID,
            secretAccessKey: process.env.R2_SECRET_ACCESS_KEY
        }
    })

    return _r2Client
}
