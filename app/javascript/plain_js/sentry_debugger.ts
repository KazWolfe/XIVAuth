import * as Sentry from "@sentry/browser";

class SentryDebugger {
    setup() {
        if (window.gon.sentry == null || window.gon.sentry.dsn == null) {
            return;
        }

        const sentryData = window.gon.sentry;

        if (sentryData.user) {
            Sentry.setUser({
                id: sentryData.user.id,
                email: sentryData.user.email,
                username: sentryData.user.username,
            });
        }

        Sentry.init({
            dsn: sentryData.dsn,
            environment: sentryData.environment,
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
            sentry?: {
                dsn: string;
                environment: string;
                user?: {
                    id: number;
                    email: string;
                    username: string;
                }
            }
        }
    }
}

window.Sentry = Sentry;
new SentryDebugger().setup();