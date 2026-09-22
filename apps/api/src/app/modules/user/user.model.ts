import bcrypt from 'bcrypt';
import { StatusCodes } from 'http-status-codes';
import { model, Schema } from 'mongoose';
import config from '../../../config';
import { USER_ROLES } from '../../../enums/user';
import ApiError from '../../../errors/ApiError';
import { IUser, UserModal } from './user.interface';

const userSchema = new Schema<IUser, UserModal>(
  {
    name: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      enum: Object.values(USER_ROLES),
      required: true,
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
    },
    password: {
      type: String,
      required: true,
      select: 0,
      minlength: 8,
    },
    image: {
      type: String,
      default: 'https://i.ibb.co/z5YHLV9/profile.png',
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'delete'],
      default: 'active',
    },
    verified: {
      type: Boolean,
      default: false,
    },
      authentication: {
      type: {
        isResetPassword: {
          type: Boolean,
          default: false,
        },
        oneTimeCode: {
          type: Number,
          default: null,
        },
        expireAt: {
          type: Date,
          default: null,
        },
      },
      select: 0,
    },
    subRole: { type: String },
    phoneNumber: { type: String },
    languagesSpoken: { type: String },
    preferredAttorney: { type: String, default: '' },
    preferredBailBondsman: { type: String, default: '' },
    licensedStatesToPractice: { type: String },
    barAssociationNumber: { type: String },
    lawFirmName: { type: String },
    officeName: { type: String },
    datePassedTheBar: { type: String },
    medicalLicenseNumber: { type: String },
    specialization: { type: String },
    companyName: { type: String },
    businessAddress: { type: String },
    badgeNumber: { type: String },
    assignedNumber: { type: String },
    departmentOrPrecinct: { type: String },
    didCarNumberChange: { type: String },
    newCarNumber: { type: String },
    licenseNumber: { type: String },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret: Record<string, unknown>) => {
        ret.id = ret._id;
        return ret;
      },
    },
    toObject: { virtuals: true },
  }
);

userSchema.virtual('shortHexId').get(function (this: { _id?: { toString(): string } }) {
  const idStr = this._id ? this._id.toString() : '';
  return idStr.length >= 8 ? idStr.slice(-8).toUpperCase() : idStr.toUpperCase();
});

userSchema.index({ email: 1, role: 1 }, { unique: true });

//exist user check
userSchema.statics.isExistUserById = async (id: string) => {
  const isExist = await User.findById(id);
  return isExist;
};

userSchema.statics.isExistUserByEmail = async (email: string) => {
  const isExist = await User.findOne({ email });
  return isExist;
};

userSchema.statics.isExistUserByEmailAndRole = async (email: string, role: string) => {
  const isExist = await User.findOne({ email, role });
  return isExist;
};

//is match password
userSchema.statics.isMatchPassword = async (
  password: string,
  hashPassword: string
): Promise<boolean> => {
  return await bcrypt.compare(password, hashPassword);
};

//check user
userSchema.pre('save', async function (next) {
  if (this.isNew) {
    const isExist = await User.findOne({ email: this.email, role: this.role });
    if (isExist) {
      throw new ApiError(StatusCodes.BAD_REQUEST, 'Email and Role combination already exists!');
    }
  }

  //password hash
  if (this.isModified('password')) {
    this.password = await bcrypt.hash(
      this.password,
      Number(config.bcrypt_salt_rounds)
    );
  }
  next();
});

export const User = model<IUser, UserModal>('User', userSchema);
