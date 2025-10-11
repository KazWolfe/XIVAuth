import * as Sentry from "@sentry/browser";

class SentryDebugger {
    setup() {
        if (window.gon.env == "development") {
            return;
        }

        if (window.gon.user) {
            Sentry.setUser({
                id: window.gon.user.id,
                email: window.gon.user.email,
                username: window.gon.user.name,
            });
        }

        Sentry.init({
            dsn: "https://d26e06e98289421f9eb53d5d892ab660@o4505361640325120.ingest.us.sentry.io/4505361641504768",
            // Setting this option to true will send default PII data to Sentry.
            // For example, automatic IP address collection on events
            sendDefaultPii: true,
            integrations: [
                Sentry.feedbackIntegration({
                    colorScheme: "system",
                    useSentryUser: {
                        name: "username",
                        email: "email",
                    },
                }),
            ]
        });
    }
}

declare global {
    interface Window {
        Sentry: typeof Sentry;

        gon: {
            env: string;
            user?: {
                id: string;
                email: string;
                name: string;
            }
        }
    }
}

window.Sentry = Sentry;
new SentryDebugger().setup();