export interface Env {
    BUCKET: R2Bucket;
    AUTH_SECRET: string;
}

export default {
    async fetch(
        request: Request,
        env: Env,
        ctx: ExecutionContext,
    ): Promise<Response> {
        const url = new URL(request.url);

        // Handle CORS
        if (request.method === "OPTIONS") {
            return new Response(null, {
                headers: {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
                    "Access-Control-Allow-Headers": "*",
                },
            });
        }

        // Logic: Serve Files (GET)
        if (request.method === "GET") {
            const objectName = url.pathname.slice(1); // remove leading slash

            if (!objectName) {
                return new Response("Missing path", { status: 400 });
            }

            // 1. Auth Check (Token in Query Params)
            const token = url.searchParams.get("token");
            const expires = url.searchParams.get("expires");

            // Allow public access? (User said private, so we enforce auth)
            // If you want public, remove this block.
            if (!env.AUTH_SECRET) {
                // If no secret configured, fail closed (or open if intended, but let's be safe)
                return new Response(
                    "Worker misconfigured: AUTH_SECRET missing",
                    { status: 500 },
                );
            }

            if (!token || !expires) {
                return new Response("Unauthorized: Missing token/expires", {
                    status: 403,
                });
            }

            // Check Expiry
            if (Date.now() > parseInt(expires)) {
                return new Response("Unauthorized: Token expired", {
                    status: 403,
                });
            }

            // Verify Signature
            // We implement a "Directory Scope" logic.
            // Expected Signature = HMAC_SHA256(secret, "/usr/" + expires)
            // But to be generic, let's verify if the token matches the requested file, OR a parent directory.
            // For simplicity and matching the "refresh-hash" flow, let's assume valid scope is the first directory segment (e.g., "/usr/") or root "/".
            // Let's Validate: Signature == HMAC(secret, objectName + expires)

            // WAIT! The previous system generated a token for "/usr/".
            // If we want to keep that efficiency (1 token for all images), we need to validate against the PREFIX.
            // Let's assume the token is valid for "/usr/".
            // We need to know WHAT the token was signed for.
            // Typically we include "scope" in URL or assume a standard scope.
            // Let's support verifying signature against a fixed prefix "/" (Global access for authenticated user) or specific path.

            const encoder = new TextEncoder();
            const key = await crypto.subtle.importKey(
                "raw",
                encoder.encode(env.AUTH_SECRET),
                { name: "HMAC", hash: "SHA-256" },
                false,
                ["verify"],
            );

            // We check if the token signs the full path OR a prefix
            // Strategy: We will sign "/path/to/file" OR "/path/"
            // Ideally we'd pass `?scope=/path/` in the URL to know what to verify.
            // But let's try to verify the hardcoded prefix "/usr/" (since that's what we used) + expires.

            // Better Strategy for generic usage:
            // The signature passed must verify "SCOPE + EXPIRES".
            // And "OBJECT_NAME" must start with "SCOPE".
            // But we don't know SCOPE from query params.

            // Let's require `?scope=` param.
            // If missing, assume scope is the full path.

            const scope = url.searchParams.get("scope") || objectName;

            // Validate Scope
            if (!objectName.startsWith(scope) && scope !== "/") {
                // Trying to access 'secret.txt' with scope '/images/' -> Fail.
                // If scope is filename, startsWith is true.
                return new Response("Unauthorized: Invalid Scope", {
                    status: 403,
                });
            }

            const dataToVerify = scope + expires;
            const signatureBytes = Uint8Array.from(
                atob(token).split("").map((c) => c.charCodeAt(0)),
            );

            const isValid = await crypto.subtle.verify(
                "HMAC",
                key,
                signatureBytes,
                encoder.encode(dataToVerify),
            );

            if (!isValid) {
                return new Response("Unauthorized: Invalid Signature", {
                    status: 403,
                });
            }

            // 2. Fetch from R2
            const object = await env.BUCKET.get(objectName);

            if (object === null) {
                return new Response("Object Not Found", { status: 404 });
            }

            const headers = new Headers();
            object.writeHttpMetadata(headers);
            headers.set("etag", object.httpEtag);
            headers.set("Access-Control-Allow-Origin", "*");

            return new Response(object.body, {
                headers,
            });
        }

        return new Response("Method Not Allowed", {
            status: 405,
            headers: {
                Allow: "GET",
            },
        });
    },
};
