import mongoose from 'mongoose';
import config from '../config';
import { User } from '../app/modules/user/user.model';
import { MeetingService } from '../app/modules/meeting/meeting.service';
import { USER_ROLES } from '../enums/user';

async function main() {
  await mongoose.connect(config.database_url as string);

  let citizen = await User.findOne({ email: 'citizen.test@govia.com', role: USER_ROLES.CITIZEN });
  if (!citizen) {
    citizen = await User.create({
      name: 'Adnan Citizen',
      email: 'citizen.test@govia.com',
      role: USER_ROLES.CITIZEN,
      password: 'Password123!',
      verified: true,
      status: 'active',
      phoneNumber: '+1 (555) 012-3456',
    });
  }

  const meeting = await MeetingService.createInstantMeeting(
    citizen._id.toString(),
    'Traffic Stop - Highway 71',
    undefined,
    false
  );

  console.log('CALL_CREATED_OK');
  console.log('MEETING_ID:', meeting.meetingId);
  console.log('ROOM_NAME:', meeting.roomName);
  console.log('TOKEN:', meeting.token);

  await mongoose.disconnect();
  process.exit(0);
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
