# Project Overview

XIVAuth is a Ruby application that allows users log in to external services using a centralized set of credentials. It
is, ultimately, a single sign-on (SSO) solution for the Final Fantasy XIV community. Users can register and manage 
characters for use with external services, such as Discord bots, websites, and more.

Due to the nature of XIVAuth, it is imperative that the application is secure and reliable. Care must be taken to ensure
that all industry best practices are followed at all times, and that design choices are clear and thoughtful. While the
application may be considered "sophisticated", it should remain simple for both maintainability and auditability 
purposes. The application also has a strong focus on user privacy. Minimal data is collected and logged, and information
provided to external services must be carefully controlled.

Models working on this codebase should keep a "light touch" approach in mind, trying to find simple solutions using
the standard libraries and frameworks available in the Ruby on Rails ecosystem. When additional functionality is
required, it should be implemented in a clear and concise fashion. Models should take care to only solve the precise
problem at hand, and should avoid expanding scope. Models should also inform the developer when a request is likely to
conflict with the design philosophy outlined here, and wait for further instructions instead of taking direct action.

## Project Structure

This project follows the standard Ruby on Rails structure. It uses the following notable libraries and components:

- **Devise**: For user authentication and management.
- **Omniauth**: For authentication from external services (e.g. Discord, Steam).
- **Doorkeeper**: For providing OAuth 2.0 to other applications.
  - Note: Certain Doorkeeper behaviors may be heavily customized to fit XIVAuth's needs.
- **Stimulus**: Provides a simple (and Rails-friendly) way to add JavaScript interactivity to the application.
- **Hotwire**: Adds SPA-like behavior without a dedicated frontend framework.
- **Bootstrap**: For styling and layout. Specifically, a theme named Hope UI is used.

## User Interface Guidelines

XIVAuth's user interface needs to be trustworthy and simple to use. The application should be easy to navigate and not
overwhelm users. At the same time, it should be visually appealing and make behavior clear. Users should not be
surprised.