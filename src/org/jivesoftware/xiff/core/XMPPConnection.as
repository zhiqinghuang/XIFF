﻿package org.jivesoftware.xiff.core{
	
	/*
	 * Copyright (C) 2003-2004 
	 * Nick Velloff <nick.velloff@gmail.com>
	 * Derrick Grigg <dgrigg@rogers.com>
	 * Sean Voisen <sean@mediainsites.com>
	 * Sean Treadway <seant@oncotype.dk>
	 *
	 * This library is free software; you can redistribute it and/or
	 * modify it under the terms of the GNU Lesser General Public
	 * License as published by the Free Software Foundation; either
	 * version 2.1 of the License, or (at your option) any later version.
	 * 
	 * This library is distributed in the hope that it will be useful,
	 * but WITHOUT ANY WARRANTY; without even the implied warranty of
	 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	 * Lesser General Public License for more details.
	 * 
	 * You should have received a copy of the GNU Lesser General Public
	 * License along with this library; if not, write to the Free Software
	 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
	 *
	 */
	 
	import org.jivesoftware.xiff.data.IExtension;
	 
	import org.jivesoftware.xiff.data.XMPPStanza;
	import org.jivesoftware.xiff.data.IQ;
	import org.jivesoftware.xiff.data.Message;
	import org.jivesoftware.xiff.data.Presence;
	import org.jivesoftware.xiff.data.auth.AuthExtension;
	import org.jivesoftware.xiff.data.register.RegisterExtension;
	import org.jivesoftware.xiff.data.ExtensionClassRegistry;
	import org.jivesoftware.xiff.exception.SerializationException;
	
	import flash.xml.XMLNode;
	import flash.xml.XMLDocument;
	import flash.net.XMLSocket;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.events.DataEvent;
	import flash.events.SecurityErrorEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import org.jivesoftware.xiff.events.*;
	import org.jivesoftware.xiff.data.im.RosterExtension;
	import org.jivesoftware.xiff.data.forms.FormExtension;

	public class XMPPConnection extends EventDispatcher
	{
		
		protected var _useAnonymousLogin:Boolean;
		
		protected var socket:XMLSocket;
		
		protected var myServer:String;
		protected var myUsername:String;
		protected var myResource:String;
		protected var myPassword:String;
		protected var myJID:String;
	
		protected var myPort:Number;
		protected var active:Boolean;
		protected var loggedIn:Boolean;
		protected var ignoreWhitespace:Boolean;
		
		protected var openingStreamTag:String;
		protected var closingStreamTag:String;
		
		protected var sessionID:String;
		protected var pendingIQs:Object;
		
		protected var _expireTagSearch:Boolean;

		
		/**
		 * Used to add listeners for certain events. Event dispatching is handled using Macromedia's
		 * EventDispatcher class found in mx.events.EventDispatcher. Listeners can either implement a method
		 * with the same name as the event they are listening to, or a method called <code>handleEvent</code>
		 * that will handle all incoming event broadcasts. If <code>handleEvent</code> is implemented, the method
		 * can examine the event object's <code>type</code> attribute to find out which type of event occured.
		 *
		 * @availability Flash Player 9
		 * @param event The name of the event to listen to
		 * @param handler The class instance that is listening for events
		 * @example This example adds a class instance called "listener" as a listener for all <code>incomingData</code> events.
		 * <pre>var listener = new Object();
		 * listener.handleEvent = function( eventObject ) {
		 *     if( eventObject.type == "incomingData" ) {
		 *         trace( "INCOMING: " + eventObject.data );
		 *     }
		 * }
		 * myXMPPConnection.addEventListener( "incomingData", listener );
		 * </pre>
		 */
		
		public function XMPPConnection()
		{	
			// Create the socket
			socket = new XMLSocket();
			socket.addEventListener(Event.CONNECT,socketConnected);
			socket.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			socket.addEventListener(Event.CLOSE,socketClosed);
			socket.addEventListener(DataEvent.DATA,socketReceivedData);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityError);
			
			// Hash to hold callbacks for IQs
			pendingIQs = new Object();
			
			_useAnonymousLogin = false;
			active = false;
			loggedIn = false;
			ignoreWhitespace = true;
			resource = "xiff";
			port = 5222;
			
			AuthExtension.enable();
			RegisterExtension.enable();
			FormExtension.enable();
		}
		
		/**
		 * Connects to the server.
		 *
		 * @availability Flash Player 9
		 * @param streamType (Optional) The type of initial stream negotiation, either &lt;flash:stream&gt; or &lt;stream:stream&gt;. 
		 * Some servers, like Jabber, Inc.'s XCP and Jabberd 1.4 expect &lt;flash:stream&gt; from a Flash client instead of the standard &lt;stream:stream&gt;.
		 * The options for this parameter are: "flash", "terminatedFlash", "standard" and "terminatedStandard". The default is "terminatedStandard".
		 *
		 * @return A boolean indicating whether the server was found.
		 */
		public function connect( streamType:String ):Boolean
		{
			active = false;
			loggedIn = false;
			
			// Stream type lets user set opening/closing tag - some servers (jadc2s) prefer <stream:flash> to the standard
			// <stream:stream>
			switch( streamType ) {
				case "flash":
					openingStreamTag = new String( "<?xml version=\"1.0\"?><flash:stream to=\"" + server + "\" xmlns=\"jabber:client\" xmlns:flash=\"http://www.jabber.com/streams/flash\" version=\"1.0\">" );
					closingStreamTag = new String( "</flash:stream>" );
					break;
					
				case "terminatedFlash":
					openingStreamTag = new String( "<?xml version=\"1.0\"?><flash:stream to=\"" + server + "\" xmlns=\"jabber:client\" xmlns:flash=\"http://www.jabber.com/streams/flash\" version=\"1.0\" />" );
					closingStreamTag = new String( "</flash:stream>" );
					break;
					
				case "standard":
					openingStreamTag = new String( "<?xml version=\"1.0\"?><stream:stream to=\"" + server + "\" xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\" version=\"1.0\">" );
					closingStreamTag = new String( "</stream:stream>" );
					break;
			
				case "terminatedStandard":
				default:
					openingStreamTag = new String( "<?xml version=\"1.0\"?><stream:stream to=\"" + server + "\" xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\" version=\"1.0\" />" );
					closingStreamTag = new String( "</stream:stream>" );
					break;
			}
			socket.connect( server, port );
			return true;
		}
		
		/**
		 * Disconnects from the server if currently connected. After disconnect, a <code>disconnection</code> event is broadcast.
		 *
		 * @availability Flash Player 9
		 * @see #disconnection
		 */
		public function disconnect():void
		{
			if( isActive() ) {
				sendXML( closingStreamTag );
				socket.close();
				active = false;
				loggedIn = false;
				var event:DisconnectionEvent = new DisconnectionEvent();
				dispatchEvent(event);
			}
		}
		
		/**
		 * Sends data to the server. If the data to send cannot be serialized properly, this method throws a SerializeException.
		 *
		 * @availability Flash Player 9
		 * @param o The data to send. This must be an instance of a class that implements the ISerializable interface.
		 * @see org.jivesoftware.xiff.data.ISerializable
		 * @example The following example sends a basic chat message to the user with the JID "sideshowbob@springfieldpenitentiary.gov".
		 * <pre>var msg:Message = new Message( "sideshowbob@springfieldpenitentiary.gov", null, "Hi Bob.", "<b>Hi Bob.</b>", Message.CHAT_TYPE );
		 * myXMPPConnection.send( msg );</pre>
		 */
		public function send( o:XMPPStanza ):void
		{
			if( isActive() ) {
				if( o is IQ ) {
	                var iq:IQ = o as IQ;
	                if (iq.callbackName != null && iq.callbackScope != null)
	                {
	                	addIQCallbackToPending( iq.id, iq.callbackName, iq.callbackScope, iq.callback );
	                }		
				}
				var root:XMLNode = o.getNode().parentNode;
				if (root == null) {
					root = new XMLDocument();
				}
	
				if (o.serialize(root)) {
					sendXML( root.firstChild );
				} else {
					throw new SerializationException();
				}
			}
		}
		
		/**
		 * Determines whether the connection with the server is currently active. (Not necessarily logged in.
		 * For login status, use the <code>isLoggedIn()</code> method.)
		 * 
		 * @availability Flash Player 9
		 * @return A boolean indicating whether the connection is active.
		 * @see org.jivesoftware.xiff.core.XMPPConnection#isLoggedIn
		 */
		public function isActive():Boolean
		{
			return active;
		}
		
		/**
		 * Determines whether the user is connected and logged into the server.
		 * 
		 * @availability Flash Player 9
		 * @return A boolean indicating whether the user is logged in.
		 * @see org.jivesoftware.xiff.core.XMPPConnection#isActive
		 */
		public function isLoggedIn():Boolean
		{
			return loggedIn;
		}
		
		/**
		 * Issues a request for the information that must be submitted for registration with the server.
		 * When the data returns, an event of type "registrationFields" is broadcast containing the requested data.
		 *
		 * @availability Flash Player 9
		 */
		public function getRegistrationFields():void
		{
			var regIQ:IQ = new IQ( server, IQ.GET_TYPE, XMPPStanza.generateID("reg_info_"), "getRegistrationFields_result", this, null);
			regIQ.addExtension(new RegisterExtension(regIQ.getNode()));
	
			send( regIQ );
		}
		
		/**
		 * Registers a new account with the server, sending the registration data as specified in the fieldMap paramter.
		 *
		 * @param fieldMap An object map containing the data to use for registration. The map should be composed of attribute:value pairs for each registration data item.
		 * @param key (Optional) If a key was passed in the "data" field of the "registrationFields" event, that key must also be passed here.
		 * required field needed for registration.
		 * @availability Flash Player 9
		 */
		public function sendRegistrationFields( fieldMap:Object, key:String ):void
		{
			var regIQ:IQ = new IQ( server, IQ.SET_TYPE, XMPPStanza.generateID("reg_attempt_"), "sendRegistrationFields_result", this, null );
			var ext:RegisterExtension = new RegisterExtension(regIQ.getNode());
	
			for( var i:String in fieldMap ) {
				ext[i] = fieldMap[i];
			}
			if (key != null) {
				ext.key = key;
			}
	
			regIQ.addExtension(ext);
			send( regIQ );
		}
		
		/**
		 * Changes the user's account password on the server. If the password change is successful, the class will broadcast a <code>changePasswordSuccess</code> event.
		 *
		 * @param newPassword The new password
		 * @availability Flash Player 9
		 * @see #changePasswordSuccess
		 * @example The following example waits for a change password success, and updates the password stored in the XMPPConnection class, in case
		 * the same class instance is used for future connections.
		 * <pre>var newPasswd:String = "12345";
		 * listener = new Object();
		 * listener.changePasswordSuccess = function( eventObject ) {
		 *     trace( "Password changed!" );
		 *     myXMPPConnection.password = newPasswd;
		 * }
		 * myXMPPConnection.addEventListener( "changePasswordSuccess", listener );
		 *
		 * myXMPPConnection.changePassword( newPasswd );
		 * </pre>
		 */
		public function changePassword( newPassword:String ):void
		{
			var passwdIQ:IQ = new IQ( server, IQ.SET_TYPE, XMPPStanza.generateID("pswd_change_"), "changePassword_result", this, null );
			var ext:RegisterExtension = new RegisterExtension(passwdIQ.getNode());
	
			ext.username = getBareJID();
			ext.password = newPassword;
	
			passwdIQ.addExtension(ext);
			send( passwdIQ );
		}
		
		/**
		 * Gets the fully qualified JID (user@server/resource) of the user. A fully-qualified JID includes the resource. A bare JID does not.
		 * To get the bare JID, use the <code>getBareJID()</code> method.
		 *
		 * @return The fully qualified JID
		 * @see #getBareJID
		 * @availability Flash Player 9
		 */
		public function getJID():String
		{
			return myJID;
		}
		
		/**
		 * Gets the bare JID (non-fully qualified: user@server) of the user. The bare JID does not include the resource.
		 *
		 * @return The bare JID
		 * @see #getJID
		 * @availability Flash Player 9
		 */
		public function getBareJID():String
		{
			// NOTE: what happens with anonymous login?
			return getJID().split( "/" )[0];
		}
		
		protected function changePassword_result( resultIQ:IQ ):void
		{
			if( resultIQ.type == IQ.RESULT_TYPE ) {
				var event:ChangePasswordSuccessEvent = new ChangePasswordSuccessEvent();
				dispatchEvent(event);
			}
			else {
				// We weren't expecting this
				dispatchError( "unexpected-request", "Unexpected Request", "wait", 400 );
			}
		}
		
		protected function getRegistrationFields_result( resultIQ:IQ ):void
		{
			try
			{
				var ext:RegisterExtension = resultIQ.getAllExtensionsByNS(RegisterExtension.NS)[0];
				var fields:Array = ext.getRequiredFieldNames(); //TODO, phase this out
				
				var event:RegistrationFieldsEvent = new RegistrationFieldsEvent();
				event.fields = fields;
				event.data = ext;
			}
			catch (e:Error)
			 {
			 	trace("Error : null trapped. Resuming.");
			 }
		}
		
		protected function sendRegistrationFields_result( resultIQ:IQ ):void
		{
			if( resultIQ.type == IQ.RESULT_TYPE ) {

				var event:RegistrationSuccessEvent = new RegistrationSuccessEvent();
				dispatchEvent( event );
			}
			else {
				// We weren't expecting this
				dispatchError( "unexpected-request", "Unexpected Request", "wait", 400 );
			}
		}
		
		// Listener function from the ListenerXMLSocket
		protected function socketConnected(ev:Event):void
		{
			sendXML( openingStreamTag );
			active = true;
			var event:ConnectionSuccessEvent = new ConnectionSuccessEvent();
			dispatchEvent( event );
		}
		protected function socketReceivedData( ev:DataEvent ):void
		{
			// parseXML is more strict in AS3 so we must check for the presence of flash:stream
			// the unterminated tag should be in the first string of xml data retured from the server
			if (!_expireTagSearch) 
			{
				var pattern:RegExp = new RegExp("<flash:stream");
				var resultObj:Object = pattern.exec(ev.data);
				if (resultObj != null) // stop searching for unterminated node
				{
					ev.data = ev.data.concat("</flash:stream>");
					_expireTagSearch = true;
				}
			}
			
			var xmlData:XMLDocument = new XMLDocument();
			xmlData.ignoreWhite = this.ignoreWhite;
			xmlData.parseXML( ev.data );
			
			var event:IncomingDataEvent = new IncomingDataEvent();
			event.data = xmlData;
			dispatchEvent( event );
			
			// Read the data and send it to the appropriate parser
			var firstNode:XMLNode = xmlData.firstChild;
			var nodeName:String = firstNode.nodeName.toLowerCase();
			
			switch( nodeName )
			{
				case "stream:stream":
				case "flash:stream":
					_expireTagSearch = false;
					handleStream( firstNode );
					break;
					
				case "stream:error":
					handleStreamError( firstNode );
					break;
					
				case "iq":
					handleIQ( firstNode );
					break;
					
				case "message":
					handleMessage( firstNode );
					break;
					
				case "presence":
					handlePresence( firstNode );
					break;
					
				default:
					// silently ignore lack of or unknown stanzas
					// if the app designer wishes to handle raw data they
					// can on "incomingData".
	
					// Use case: received null byte, XMLSocket parses empty document
					// sends empty document
					
					// I am enabling this for debugging
					dispatchError( "undefined-condition", "Unknown Error", "modify", 500 );
					break;
			}
		}
		
		protected function socketClosed(e:Event):void
		{	
			var event:DisconnectionEvent = new DisconnectionEvent();
			dispatchEvent( event );
		}
		
		protected function handleStream( node:XMLNode ):void
		{
			sessionID = node.attributes.id;
			
			if(_useAnonymousLogin) {
				// Begin anonymous login
				sendAnonymousLogin();
			} else if( username != null && username.length > 0 ) {
				// Begin login sequence
				beginAuthentication();
			} else {
				//get registration fields
				getRegistrationFields();
			}
		}
		
		protected function handleStreamError( node:XMLNode ):void
		{
			dispatchError( "service-unavailable", "Remote Server Error", "cancel", 502 );
			
			// Cancel everything by closing connection
			socket.close();
			active = false;
			loggedIn = false;
			var event:DisconnectionEvent = new DisconnectionEvent();
			dispatchEvent( event );
		}
		
		protected function handleIQ( node:XMLNode ):IQ
		{
			var iq:IQ = new IQ();
			// Populate the IQ with the incoming data
			if( !iq.deserialize( node ) ) {
				throw new SerializationException();
			}
			
			// If it's an error, handle it
			
			if( iq.type == IQ.ERROR_TYPE ) {
				dispatchError( iq.errorCondition, iq.errorMessage, iq.errorType, iq.errorCode );
			}
			else {
				
				// Start the callback for this IQ if one exists
				if( pendingIQs[iq.id] !== undefined ) {
					var callbackInfo:* = pendingIQs[iq.id];
					
					callbackInfo.methodScope[callbackInfo.methodName].apply( callbackInfo.methodScope, [iq] );					
					if (callbackInfo.func != null) { 
						callbackInfo.func( iq );
					}
					pendingIQs[iq.id] = null;
					delete pendingIQs[iq.id];
				}
				else {
					var exts:Array = iq.getAllExtensions();
					for (var ns:String in exts) {
						// Static type casting
						var ext:IExtension = exts[ns] as IExtension;
						if (ext != null) {
							var event:IQEvent = new IQEvent(ext.getNS());
							event.data = ext;
							event.iq = iq;
							dispatchEvent( event );
						}
					}
				}
			}
	        return iq;
		}
		
		protected function handleMessage( node:XMLNode ):Message
		{
			var msg:Message = new Message();
			
			// Populate with data
			if( !msg.deserialize( node ) ) {
				throw new SerializationException();
			}
			// ADDED in error handling for messages
			if( msg.type == Message.ERROR_TYPE ) {
				dispatchError( msg.errorCondition, msg.errorMessage, msg.errorType, msg.errorCode );
			}
			else
			{
				var event:MessageEvent = new MessageEvent();
				event.data = msg;
				dispatchEvent( event );		
			}
	        return msg;
		}
		
		protected function handlePresence( node:XMLNode ):Presence
		{
			var pres:Presence = new Presence();
			
			// Populate
			if( !pres.deserialize( node ) ) {
				throw new SerializationException();
			}
			var event:PresenceEvent = new PresenceEvent();
			event.data = pres;
			dispatchEvent( event );
	
	        return pres;
		}
		
		protected function updateJID():void
		{
			// Update the user ID with the latest server/user information
			if(!_useAnonymousLogin) {
				myJID = username + "@" + server + "/" + resource;
			} else {
				myJID = server + "/" + resource;
			}
		}
		protected function onIOError(event:IOErrorEvent):void{
			/*
			this fires the standard dispatchError method. need to add
			the appropriate error code
			*/
			dispatchError( "service-unavailable", "Service Unavailable", "cancel", 503 );
		}
		
		protected function securityError(event:SecurityErrorEvent):void{
			trace("there was a security error of type: " + event.type + "\nError: " + event.text);
			dispatchError( "not-authorized", "Not Authorized", "auth", 401 );
		}
		
		protected function dispatchError( condition:String, message:String, type:String, code:Number ):void
		{
			var event:XIFFErrorEvent = new XIFFErrorEvent();
			event.errorCondition = condition;
			event.errorMessage = message;
			event.errorType = type;
			event.errorCode = code;
			dispatchEvent( event );
		}
		
		protected function sendXML( someData:* ):void
		{
			// Data is untyped because it could be a string or XML
			socket.send( someData );
			var event:OutgoingDataEvent = new OutgoingDataEvent();
			event.data = someData;
			dispatchEvent( event );
		}
		
		// anonymous login
		protected function sendAnonymousLogin():void {
			var anonIQ:IQ = new IQ(null, IQ.SET_TYPE, XMPPStanza.generateID("log_anom_"), "sendAnonymousLogin_result", this, null );
			var authExt:AuthExtension = new AuthExtension(anonIQ.getNode());
			anonIQ.addExtension(authExt);
			send(anonIQ);
		}
		
		protected function sendAnonymousLogin_result(resultIQ:IQ):void {
			if( resultIQ.type == IQ.RESULT_TYPE ) {
				try
				{
					// update resource
					var resultAuth:Array = resultIQ.getAllExtensionsByNS(AuthExtension.NS)[0];
					resource = resultAuth.resource;
					// dispatch login event
					loggedIn = true;
					var event:LoginEvent = new LoginEvent();
					dispatchEvent( event );
				}
				catch (e:Error)
				{
					trace("Error : null trapped. Resuming.");
				}
			}
		}
		
		protected function beginAuthentication():void
		{
			var authIQ:IQ = new IQ( null, IQ.GET_TYPE, XMPPStanza.generateID("log_user_"), "beginAuthentication_result", this, null );
			var authExt:AuthExtension = new AuthExtension(authIQ.getNode());
			authExt.username = username
			
			authIQ.addExtension(authExt);
			send( authIQ );
		}
		
		protected function beginAuthentication_result( resultIQ:IQ ):void
		{
			var connectionType:String = "none";
	
			// Begin authentication procedure
			if( resultIQ.type == IQ.RESULT_TYPE ) {
				var authIQ:IQ = new IQ( null, IQ.SET_TYPE, XMPPStanza.generateID("log_user2_"), "sendAuthentication_result", this, null );
				try
				{
					var resultAuth:* = resultIQ.getAllExtensionsByNS(AuthExtension.NS)[0];
					var responseAuth:AuthExtension = new AuthExtension(authIQ.getNode());
					responseAuth.password = password;
					responseAuth.username = username;
					responseAuth.resource = resource;
					authIQ.addExtension(responseAuth);
					send( authIQ );
				}
				catch (e:Error)
				{
					trace("Error : null trapped. Resuming.");
				}
			}
			else {
				// We weren't expecting this
				dispatchError( "unexpected-request", "Unexpected Request", "wait", 400 );
			}
		}
		
		protected function sendAuthentication_result( resultIQ:IQ ):void
		{
			if( resultIQ.type == IQ.RESULT_TYPE ) {
				loggedIn = true;
				var event:LoginEvent = new LoginEvent();
				dispatchEvent( event );
			}
			else {
				// We weren't expecting this
				dispatchError( "unexpected-request", "Unexpected Request", "wait", 400 );
			}
		}
		
		protected function addIQCallbackToPending( id:String, callbackName:String, callbackScope:Object, callbackFunc:Function ):void
		{
			pendingIQs[id] = {methodName:callbackName, methodScope:callbackScope, func:callbackFunc};
		}
		
		/**
		 * The XMPP server to use for connection.
		 *
		 * @availability Flash Player 9
		 */
		public function get server():String
		{
			return myServer;
		}
		
		public function set server( theServer:String ):void
		{
			myServer = theServer;
			
			updateJID();
		}
		
		/**
		 * The username to use for connection. If this property is null when <code>connect()</code> is called,
		 * the class will fetch registration field data rather than attempt to login.
		 *
		 * @availability Flash Player 9
		 */
		public function get username():String
		{
			return myUsername;
		}
		
		public function set username( theUsername:String ):void
		{
			myUsername = theUsername;
			
			updateJID();
		}
		
		/**
		 * The password to use when logging in.
		 *
		 * @availability Flash Player 9
		 */
		public function get password():String
		{
			return myPassword;
		}
		
		public function set password( thePassword:String ):void
		{
			myPassword = thePassword;
		}
		
		/**
		 * The resource to use when logging in. A resource is required (defaults to "XIFF") and allows a user to login using the same account
		 * simultaneously (most likely from multiple machines). Typical examples of the resource include "Home" or "Office" to indicate
		 * the user's current location.
		 *
		 * @availability Flash Player 0
		 */
		public function get resource():String
		{
			return myResource;
		}
		
		public function set resource( theResource:String ):void
		{
			if( theResource.length > 0 )
			{
				myResource = theResource;
			
				updateJID();
			}
		}
		
		
		public function get useAnonymousLogin():Boolean { return _useAnonymousLogin; }
		public function set useAnonymousLogin(value:Boolean):void {
			// set only if not connected
			if(!isActive()) _useAnonymousLogin = value;
		}
			
		
		/**
		 * The port to use when connecting. The default XMPP port is 5222.
		 *
		 * @availability Flash Player 9
		 */
		public function get port():Number
		{
			return myPort;
		}
		
		public function set port( portNum:Number ):void
		{
			myPort = portNum;
		}
	
		/**
		 * Determines whether whitespace will be ignored on incoming XML data.
		 * Behaves the same as XML.ignoreWhite
		 *
		 * @availability Flash Player 9
		 */
		public function get ignoreWhite():Boolean
		{
			return ignoreWhitespace;
		}
	
		public function set ignoreWhite( val:Boolean ):void
		{
			ignoreWhitespace = val;
		}
	}
}