/**
 * com.skitsanos.api.JsonBridge
 * JsonBridge ActionScript Client
 * @author skitsanos, info@skitsanos.com
 * @version 1.3
 * @created 03/01/11
 * @updated 01/20/2013
 */
package com.skitsanos.api
{
	import com.adobe.net.URI;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;

	import org.httpclient.HttpClient;
	import org.httpclient.HttpRequest;
	import org.httpclient.events.HttpDataEvent;
	import org.httpclient.events.HttpResponseEvent;
	import org.httpclient.events.HttpStatusEvent;
	import org.httpclient.http.Get;

	public class JsonBridge
	{
		public static var url:String = '/jsonbridge/';
		public static var useAuthorization:Boolean = false;
		public static var authorizationHeader:URLRequestHeader = null;

		/**
		 * Executes JsonBridge API call to remote endpoint
		 * @param classpath Classpath for a call, requires complete namespace and class path
		 * @param method method within a class to call via JsonBridge
		 * @param params parameters to send, if any, if none, use null instead
		 * @param resultHandler handler for successfully executed call
		 * @param faultHandler handler for call execution failures and errors
		 */
		public static function execute(classpath:String, method:String, params:Array, resultHandler:Function, faultHandler:Function):void
		{
			var actualUrl:String;

			actualUrl = url + classpath + '/';

			if (method != null && method != '')
			{
				actualUrl += method;
			}

			trace('JsonBridge call URL: ' + actualUrl);

			if (params != null && params.length != 0)
			{
				var requestPOST:URLRequest = new URLRequest(actualUrl);

				if (useAuthorization && authorizationHeader != null)
				{
					trace(authorizationHeader.value);
					requestPOST.requestHeaders.push(authorizationHeader);
				}

				requestPOST.contentType = "application/json";
				requestPOST.method = "POST";
				requestPOST.data = JSON.stringify(params);

				var loader:URLLoader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.TEXT;
				loader.addEventListener(Event.COMPLETE, function (e:Event):void
				{
					var result:Object = JSON.parse(e.target.data);
					resultHandler(result);
				});
				loader.addEventListener(IOErrorEvent.IO_ERROR, function (e:IOErrorEvent):void
				{
					faultHandler({type: 'error', message: e.text});
				});
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function (e:SecurityErrorEvent):void
				{
					faultHandler({type: 'error', message: e.text});
				});

				loader.load(requestPOST);
			}
			else
			{
				//http://code.google.com/p/as3httpclientlib/wiki/Examples
				var client:HttpClient = new HttpClient();
				var requestGET:HttpRequest = new Get();
				requestGET.contentType = "application/json";
				if (useAuthorization && authorizationHeader != null)
				{
					requestGET.addHeader('Authorization', authorizationHeader.value)
				}
				client.listener.onStatus = function (event:HttpStatusEvent):void
				{
					switch (int(event.code))
					{
						case 200:
							trace(actualUrl + ' -- ' + event.response.message);
							break;

						case 500:
							faultHandler({type: 'error', message: event.response.message});
							break;
					}
				};
				client.listener.onComplete = function (event:HttpResponseEvent):void
				{
					// Notified when complete (after status and data)
				};
				client.listener.onData = function (event:HttpDataEvent):void
				{
					trace('GET: ' + event.bytes.readUTFBytes(event.bytes.length));
					event.bytes.position = 0;
					var parsedResult:Object = JSON.parse(event.bytes.readUTFBytes(event.bytes.length));
					if (parsedResult.type == 'error')
					{
						faultHandler(parsedResult);
					}
					else
					{
						resultHandler(parsedResult);
					}
				};

				client.request(new URI(actualUrl), requestGET);
			}
		}
	}
}
