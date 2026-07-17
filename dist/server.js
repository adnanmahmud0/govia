"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const mongoose_1 = __importDefault(require("mongoose"));
const socket_io_1 = require("socket.io");
const app_1 = __importDefault(require("./app"));
const config_1 = __importDefault(require("./config"));
const seedAdmin_1 = require("./DB/seedAdmin");
const socketHelper_1 = require("./helpers/socketHelper");
//uncaught exception
process.on('uncaughtException', () => {
    process.exit(1);
});
let server = null;
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            yield mongoose_1.default.connect(config_1.default.database_url);
            console.log('Database connected successfully');
            //Seed Super Admin after database connection is successful
            yield (0, seedAdmin_1.seedSuperAdmin)();
            const port = typeof config_1.default.port === 'number' ? config_1.default.port : Number(config_1.default.port);
            const host = config_1.default.ip_address || 'localhost';
            server = app_1.default.listen(port, host, () => {
                console.log(`Server is running at http://${host}:${port}`);
            });
            //socket
            const io = new socket_io_1.Server(server, {
                pingTimeout: 60000,
                cors: {
                    origin: '*',
                },
            });
            socketHelper_1.socketHelper.socket(io);
            // @ts-expect-error: attach io to global
            global.io = io;
        }
        catch (_error) {
            console.error('Server startup error:', _error);
        }
        //handle unhandleRejection
        process.on('unhandledRejection', () => {
            if (server) {
                server.close(() => {
                    process.exit(1);
                });
            }
            else {
                process.exit(1);
            }
        });
    });
}
main();
//SIGTERM
process.on('SIGTERM', () => {
    if (server) {
        server.close();
    }
});
