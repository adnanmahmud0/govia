import config from '../../../config';
import ApiError from '../../../errors/ApiError';
import { StatusCodes } from 'http-status-codes';
import { Meeting } from './meeting.model';
import { Types } from 'mongoose';

const getZoomAccessToken = async () => {
  const { accountId, clientId, clientSecret } = config.zoom;
  
  if (!accountId || !clientId || !clientSecret) {
    throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, 'Zoom credentials are not configured properly');
  }

  const tokenUrl = `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`;
  const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  try {
    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${authHeader}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('Zoom token error:', errorData);
      throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, `Failed to get Zoom access token: ${errorData}`);
    }

    const data = await response.json();
    return data.access_token;
  } catch (error: any) {
    console.error('Catch error in getZoomAccessToken:', error);
    if (error instanceof ApiError) throw error;
    throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, 'Error communicating with Zoom API');
  }
};

const createZoomMeeting = async (userId: string, topic: string) => {
  const accessToken = await getZoomAccessToken();
  const meetingUrl = 'https://api.zoom.us/v2/users/me/meetings';

  try {
    const response = await fetch(meetingUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        topic,
        type: 1, // Instant meeting
        settings: {
          host_video: true,
          participant_video: true,
          join_before_host: false,
          mute_upon_entry: true,
          auto_recording: 'cloud',
        }
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, `Failed to create Zoom meeting: ${errorData}`);
    }

    const data = await response.json();
    
    // Save to DB
    const newMeeting = await Meeting.create({
      userId: new Types.ObjectId(userId),
      zoomMeetingId: data.id.toString(),
      topic,
      joinUrl: data.join_url,
      startUrl: data.start_url,
      password: data.password,
    });

    return {
      meetingId: newMeeting._id,
      zoom_meeting_id: data.id,
      join_url: data.join_url,
      start_url: data.start_url,
      password: data.password
    };
  } catch (error: any) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, 'Error creating Zoom meeting');
  }
};

const getActiveMeetings = async () => {
  const activeMeetings = await Meeting.find({ status: 'ACTIVE' }).populate('userId', 'name email');
  return activeMeetings;
};

const joinMeeting = async (meetingId: string, attorneyId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  // Avoid duplicates
  const objAttorneyId = new Types.ObjectId(attorneyId);
  if (!meeting.joinedAttorneys.includes(objAttorneyId as any)) {
    meeting.joinedAttorneys.push(objAttorneyId as any);
    await meeting.save();
  }

  return { joinUrl: meeting.joinUrl };
};

const getMeetingRecordings = async (zoomMeetingId: string) => {
  const accessToken = await getZoomAccessToken();
  const url = `https://api.zoom.us/v2/meetings/${zoomMeetingId}/recordings`;

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      }
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, `Failed to fetch Zoom meeting recordings: ${errorData}`);
    }

    const data = await response.json();
    return data;
  } catch (error: any) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, 'Error fetching Zoom meeting recordings');
  }
};

const getAttorneyRecordings = async (attorneyId: string) => {
  // Find all meetings this attorney joined
  const meetings = await Meeting.find({ joinedAttorneys: new Types.ObjectId(attorneyId) });
  
  const results = [];
  for (const m of meetings) {
    try {
      const recordings = await getMeetingRecordings(m.zoomMeetingId);
      results.push({
        meeting: m,
        recordings
      });
    } catch (e) {
      // Continue even if one fails
      results.push({ meeting: m, recordings: null, error: 'Failed to fetch recordings' });
    }
  }

  return results;
};

export const MeetingService = {
  createZoomMeeting,
  getMeetingRecordings,
  getActiveMeetings,
  joinMeeting,
  getAttorneyRecordings,
};
