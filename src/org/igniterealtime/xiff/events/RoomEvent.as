/*
 * License
 */
package org.igniterealtime.xiff.events
{
	import flash.events.Event;

	public class RoomEvent extends Event
	{
		public static const SUBJECT_CHANGE:String = "subjectChange";
		public static const GROUP_MESSAGE:String = "groupMessage";
		public static const PRIVATE_MESSAGE:String = "privateMessage";
		public static const ROOM_JOIN:String = "roomJoin";
		public static const ROOM_LEAVE:String = "roomLeave";
		public static const ROOM_DESTROYED:String = "roomDestroyed";
		public static const AFFILIATIONS:String = "affiliations";
		public static const ADMIN_ERROR:String = "adminError";
		public static const PASSWORD_ERROR:String = "passwordError";
		public static const REGISTRATION_REQ_ERROR:String = "registrationReqError";
		public static const BANNED_ERROR:String = "bannedError";
		public static const MAX_USERS_ERROR:String = "maxUsersError";
		public static const LOCKED_ERROR:String = "lockedError";
		public static const USER_JOIN:String = "userJoin";
		public static const USER_DEPARTURE:String = "userDeparture";
		public static const USER_KICKED:String = "userKicked";
		public static const USER_BANNED:String = "userBanned";
		public static const NICK_CONFLICT:String = "nickConflict";
		public static const CONFIGURE_ROOM:String = "configureForm";
		public static const DECLINED:String = "declined";
		
		private var _subject:String;
		private var _data:*;
		private var _errorCondition:String;
		private var _errorMessage:String;
		private var _errorType:String;
		private var _errorCode:Number;
		private var _nickname:String;
		private var _from:String;
		private var _reason:String;
		
		public function RoomEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		override public function clone():Event
		{
			var event:RoomEvent = new RoomEvent(type, bubbles, cancelable);
			event.subject = _subject;
			event.data = _data;
			event.errorCondition = _errorCondition;
			event.errorMessage = _errorMessage;
			event.errorType = _errorType;
			event.errorCode = _errorCode;
			event.nickname = _nickname;
			event.from = _from;
			event.reason = _reason;
			return event;
		}
		override public function toString():String
		{
			return '[RoomEvent type="' + type + '" bubbles=' + bubbles + ' cancelable=' + cancelable + ' eventPhase=' + eventPhase + ']';
		}
		public function set subject(s:String) : void
		{
			_subject = s;
		}
		public function get subject() : String
		{
			return _subject;
		}
		
		/**
		 * Data type can be <code>Message</code>, <code>Array</code>, or <code>Presence</code>
		 * depending of the context.
		 * @see org.igniterealtime.xiff.data.Message
		 * @see org.igniterealtime.xiff.data.Presence
		 */
		public function set data(s:*) : void
		{
			_data = s;
		}
		public function get data() : *
		{
			return _data;
		}
		public function set errorCondition(s:String) : void
		{
			_errorCondition = s;
		}
		public function get errorCondition() : String
		{
			return _errorCondition;
		}
		public function set errorMessage(s:String) : void
		{
			_errorMessage = s;
		}
		public function get errorMessage() : String
		{
			return _errorMessage;
		}
		public function set errorType(s:String) : void
		{
			_errorType = s;
		}
		public function get errorType() : String
		{
			return _errorType;
		}
		public function set errorCode(s:Number) : void
		{
			_errorCode = s;
		}
		public function get errorCode() : Number
		{
			return _errorCode;
		}
		public function set nickname(s:String) : void
		{
			_nickname = s;
		}
		public function get nickname() : String
		{
			return _nickname;
		}
		public function set from(s:String) : void
		{
			_from = s;
		}
		public function get from() : String
		{
			return _from;
		}
		public function set reason(s:String) : void
		{
			_reason = s;
		}
		public function get reason() : String
		{
			return _reason;
		}
	}
}