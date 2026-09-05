import express from 'express';
import { V1Routes } from './v1';

const router = express.Router();

const versionRoutes = [
  {
    path: '/v1',
    route: V1Routes,
  },
];

versionRoutes.forEach(version => router.use(version.path, version.route));

export { V1Routes };
export default router;
