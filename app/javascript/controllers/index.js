// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"


import RemoteModalController from "./utilities/remote_modal_controller";
application.register("remote-modal", RemoteModalController);

import PasswordStrengthController from './devise/password_strength_controller';
application.register('password-strength', PasswordStrengthController);

import CopyCodeController from "./utilities/copy_code_controller";
application.register('copy-code', CopyCodeController);