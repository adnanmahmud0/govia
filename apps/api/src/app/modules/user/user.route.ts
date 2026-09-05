import express, { NextFunction, Request, Response } from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import fileUploadHandler from '../../middlewares/fileUploadHandler';
import validateRequest from '../../middlewares/validateRequest';
import { UserController } from './user.controller';
import { UserValidation } from './user.validation';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

router
  .route('/profile')
  .get(auth(...allRoles), UserController.getUserProfile)
  .patch(
    auth(...allRoles),
    fileUploadHandler(),
    (req: Request, res: Response, next: NextFunction) => {
      if (req.body.data) {
        req.body = UserValidation.updateUserZodSchema.parse(
          JSON.parse(req.body.data)
        );
      }
      return UserController.updateProfile(req, res, next);
    }
  );

router
  .route('/register')
  .post(
    validateRequest(UserValidation.createUserZodSchema),
    UserController.createUser
  );

router
  .route('/')
  .get(auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN), UserController.getAllUsers);

router
  .route('/create-user')
  .post(
    auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
    validateRequest(UserValidation.createUserZodSchema),
    UserController.createUserByAdmin
  );

router
  .route('/:id')
  .get(auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN), UserController.getSingleUser)
  .patch(
    auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
    fileUploadHandler(),
    (req: Request, res: Response, next: NextFunction) => {
      if (req.body.data) {
        req.body = UserValidation.adminUpdateUserZodSchema.parse(
          JSON.parse(req.body.data)
        );
      }
      return UserController.updateUser(req, res, next);
    }
  )
  .delete(auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN), UserController.deleteUser);

export const UserRoutes = router;
