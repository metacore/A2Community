MODULE libusb; (** AUTHOR "Zdenek, fnecati"; PURPOSE "libusb-1.0 binding for LinuxAos"; *)
IMPORT SYSTEM, u:=Unix, m:=Modules;

(* translation of libusb-1.0 /libusb.h/ for linux, May 2, 2017 by Zdenek and fnecati *)

(* There are some constants and structures to be added, TBD *)

CONST
 libusbname = "libusb-1.0.so.0";

TYPE 
 Uint8* = UNSIGNED8;
 Uint16* = UNSIGNED16;
 Uint32* = UNSIGNED32;
 
(* standard USB stuff *)
 (* Device and/or Interface Class codes *)
TYPE libusb_class_code* = LONGINT;
 (* In the context of a \ref libusb_device_descriptor "device descriptor",
  * this bDeviceClass value indicates that each interface specifies its
  * own class information and all interfaces operate independently.
  *)

CONST
 CLASS_PER_INTERFACE* = 0;
 CLASS_AUDIO* = 1; 	(* Audio class *)
 CLASS_COMM* = 2; 	(** Communications class *)
 CLASS_HID* = 3; 	(* Human Interface Device class *)
 CLASS_PHYSICAL* = 5; 	(* Physical *)
 CLASS_PRINTER* = 7; 	(* Printer class *)

 (* Image class *)
 CLASS_PTP* = 6; (* legacy name from libusb-0.1 usb.h *)
 CLASS_IMAGE* = 6;
	
 CLASS_MASS_STORAGE* = 8; 	(* Mass storage class *)
 CLASS_HUB* = 9; 	(* Hub class *)
 CLASS_DATA* = 10; 	(* Data class *)
 CLASS_SMART_CARD* = 0x0b; 	(* Smart Card *)
 CLASS_CONTENT_SECURITY* = 0x0d; 	(* Content Security *)
 CLASS_VIDEO* = 0x0e; 	(* Video *)
 CLASS_PERSONAL_HEALTHCARE* = 0x0f; (* Personal Healthcare *)
 CLASS_DIAGNOSTIC_DEVICE* = 0xdc; 	(* Diagnostic Device *)
 CLASS_WIRELESS* = 0xe0; 	(* Wireless class *)
 CLASS_APPLICATION* = 0xfe; 	(* Application class *)
 CLASS_VENDOR_SPEC* = 0xff; 	(* Class is vendor-specific *)
 
 
 (* Descriptor types as defined by the USB specification. *)
TYPE libusb_descriptor_type* = LONGINT;
CONST
 DT_DEVICE* = 0x01; 	(* Device descriptor. See libusb_device_descriptor. *)
 DT_CONFIG* = 0x02; 	(* Configuration descriptor. See libusb_config_descriptor. *)
 DT_STRING* = 0x03; 	(* String descriptor *)
 DT_INTERFACE* = 0x04; 	(* Interface descriptor. See libusb_interface_descriptor. *)
 DT_ENDPOINT* = 0x05; 	(* Endpoint descriptor. See libusb_endpoint_descriptor. *)
 DT_BOS* = 0x0f; 	(* BOS descriptor *)
 DT_DEVICE_CAPABILITY* = 0x10; 	(* Device Capability descriptor *)
 DT_HID* = 0x21; 	(* HID descriptor *)
 DT_REPORT* = 0x22; 	(* HID report descriptor *)
 DT_PHYSICAL* = 0x23; (* Physical descriptor *)
 DT_HUB* = 0x29; 	(* Hub descriptor *)
 DT_SUPERSPEED_HUB* = 0x2a; 	(* SuperSpeed Hub descriptor *)
 DT_SS_ENDPOINT_COMPANION* = 0x30; 	(* SuperSpeed Endpoint Companion descriptor *)


(** Descriptor sizes per descriptor type *)
	DT_DEVICE_SIZE* = 18;
	DT_CONFIG_SIZE* =  9;
	DT_INTERFACE_SIZE* = 9;
	DT_ENDPOINT_SIZE* = 7;
	DT_ENDPOINT_AUDIO_SIZE* = 9;	(* Audio extension *)
	DT_HUB_NONVAR_SIZE* = 7;
	DT_SS_ENDPOINT_COMPANION_SIZE* = 6;
	DT_BOS_SIZE* = 5;
	DT_DEVICE_CAPABILITY_SIZE* = 3;

	(* BOS descriptor sizes *)
	BT_USB_2_0_EXTENSION_SIZE* = 7;
	BT_SS_USB_DEVICE_CAPABILITY_SIZE* = 10;
	BT_CONTAINER_ID_SIZE* =	20;

	(* We unwrap the BOS => define its max size *)
	DT_BOS_MAX_SIZE*	= 	((DT_BOS_SIZE)     +
					(BT_USB_2_0_EXTENSION_SIZE)       +
					(BT_SS_USB_DEVICE_CAPABILITY_SIZE) +
					(BT_CONTAINER_ID_SIZE));

	ENDPOINT_ADDRESS_MASK* =  0x0f;    (* in bEndpointAddress *)
	ENDPOINT_DIR_MASK* = 0x80;

(* \ingroup desc
 * Endpoint direction. Values for bit 7 of the
 * \ref libusb_endpoint_descriptor::bEndpointAddress "endpoint address" scheme.

 enum libusb_endpoint_direction *)

	LIBUSB_ENDPOINT_IN* = 0x80; 	(* In: device-to-host *)
	LIBUSB_ENDPOINT_OUT* = 0x00; 	(* Out: host-to-device *)


	TRANSFER_TYPE_MASK* =	0x03;    (* in bmAttributes *)

(* \ingroup desc
 * Endpoint transfer type. Values for bits 0:1 of the
 * \ref libusb_endpoint_descriptor::bmAttributes "endpoint attributes" field.
 enum libusb_transfer_type 	*)
 
	TRANSFER_TYPE_CONTROL* = 0; (* Control endpoint *)
	TRANSFER_TYPE_ISOCHRONOUS* = 1; 	(* Isochronous endpoint *)
	TRANSFER_TYPE_BULK* = 2; 	(* Bulk endpoint *)
	TRANSFER_TYPE_INTERRUPT* = 3; 	(* Interrupt endpoint *)
	TRANSFER_TYPE_BULK_STREAM* = 4; (* Stream endpoint *)





(* \ingroup dev
 * Speed codes. Indicates the speed at which the device is operating.
    enum libusb_speed *)

	SPEED_UNKNOWN* = 0; 	(* The OS doesn't report or know the device speed. *)
	SPEED_LOW* = 1; 	(* The device is operating at low speed (1.5MBit/s). *)
	SPEED_FULL* = 2; (* The device is operating at full speed (12MBit/s). *)
	SPEED_HIGH* = 3; (* The device is operating at high speed (480MBit/s). *)
	SPEED_SUPER* = 4; (* The device is operating at super speed (5000MBit/s). *)

(* \ingroup dev
 * Supported speeds (wSpeedSupported) bitfield. Indicates what
 * speeds the device supports.

enum libusb_supported_speed *)

	LOW_SPEED_OPERATION*   = 1; 	(* Low speed operation supported (1.5MBit/s). *)
	FULL_SPEED_OPERATION*  = 2; 	(* Full speed operation supported (12MBit/s). *)
	HIGH_SPEED_OPERATION*  = 4; 	(* High speed operation supported (480MBit/s). *)
	SUPER_SPEED_OPERATION* = 8; 	(* Superspeed operation supported (5000MBit/s). *)


(* \ingroup dev
 * Masks for the bits of the
 * \ref libusb_usb_2_0_extension_descriptor::bmAttributes "bmAttributes" field
 * of the USB 2.0 Extension descriptor.
 *
enum libusb_usb_2_0_extension_attributes *)

	BM_LPM_SUPPORT* = 2; 	(* Supports Link Power Management (LPM) *)

(* \ingroup dev
 * Masks for the bits of the
 * \ref libusb_ss_usb_device_capability_descriptor::bmAttributes "bmAttributes" field
 * field of the SuperSpeed USB Device Capability descriptor.
 *
	enum libusb_ss_usb_device_capability_attributes *)

	BM_LTM_SUPPORT* = 2; 	(* Supports Latency Tolerance Messages (LTM) *)


(* \ingroup dev
 * USB capability types
 
  enum libusb_bos_type *)
	
	BT_WIRELESS_USB_DEVICE_CAPABILITY*	= 1; (* Wireless USB device capability *)
	BT_USB_2_0_EXTENSION*	= 2; (* USB 2.0 extensions *)
	BT_SS_USB_DEVICE_CAPABILITY*	= 3; (* SuperSpeed USB device capability *)
	BT_CONTAINER_ID* = 4; (* Container ID type *)
	

(*
	 * Error codes. Most libusb functions return 0 on success or one of these
	 * codes on failure.
	 * You can call libusb_error_name() to retrieve a string representation of an
	 * error code or libusb_strerror() to get an end-user suitable description of
	 * an error code.
 *)

 SUCCESS* = 0; 	(* Success (no error) *)
 ERROR_IO* = -1; 	(* Input/output error *)
 ERROR_INVALID_PARAM* = -2; 	(* Invalid parameter *)
 ERROR_ACCESS* = -3; 	(* Access denied (insufficient permissions) *)
 ERROR_NO_DEVICE* = -4; 	(* No such device (it may have been disconnected) *)
 ERROR_NOT_FOUND* = -5; 	(* Entity not found *)
 ERROR_BUSY* = -6; 	(* Resource busy *)
 ERROR_TIMEOUT* = -7; 	(* Operation timed out *)
 ERROR_OVERFLOW* = -8; 	(* Overflow *)
 ERROR_PIPE* = -9; 	(* Pipe error *)
 ERROR_INTERRUPTED* = -10; 	(* System call interrupted (perhaps due to signal) *)
 ERROR_NO_MEM* = -11; 	(* Insufficient memory *)
 ERROR_NOT_SUPPORTED* = -12; 	(* Operation not supported or unimplemented on this platform *)

 (* NB: Remember to update ERROR_COUNT below as well as the
    message strings in strerror.c when adding new error codes here. *)
 ERROR_OTHER* = -99; 	(* Other error *)
	

(* Request type bits of the
  libusb_control_setup::bmRequestType "bmRequestType" field in control
  transfers. *)	
 REQUEST_TYPE_STANDARD* = 0; (* 0 << 5 *);
 REQUEST_TYPE_CLASS* = LSH(1, 5); (* 1 << 5 *);
 REQUEST_TYPE_VENDOR* = LSH(2, 5); (* 2 << 5 *);
 REQUEST_TYPE_RESERVED* = LSH(3, 5); (* 3 << 5 *);

(* Recipient bits of the
 libusb_control_setup::bmRequestType "bmRequestType" field in control
  transfers. Values 4 through 31 are reserved. *)
 RECIPIENT_DEVICE* = 0x00; (* Device *)
 RECIPIENT_INTERFACE* = 0x01; (* Interface *)
 RECIPIENT_ENDPOINT* = 0x02; (* Endpoint *)
 RECIPIENT_OTHER* = 0x03; (* Other *)

 ISO_SYNC_TYPE_MASK* = 0x0C;


(* \ingroup misc
 * Capabilities supported by an instance of libusb on the current running
 * platform. Test if the loaded library supports a given capability by calling
 * \ref libusb_has_capability().
 *)
TYPE libusb_capability* = LONGINT;
CONST
	(* The libusb_has_capability() API is available. *)
	CAP_HAS_CAPABILITY* = 0x0000;
	(* Hotplug support is available on this platform. *)
	CAP_HAS_HOTPLUG* = 0x0001;
	(* The library can access HID devices without requiring user intervention.
	 * Note that before being able to actually access an HID device, you may
	 * still have to call additional libusb functions such as
	 * \ref libusb_detach_kernel_driver(). *)
	CAP_HAS_HID_ACCESS* = 0x0100;
	(* The library supports detaching of the default USB driver, using 
	 * \ref libusb_detach_kernel_driver(), if one is set by the OS kernel *)
	CAP_SUPPORTS_DETACH_KERNEL_DRIVER* = 0x0101;




 (*  Log message levels.
 *  - LIBUSB_LOG_LEVEL_NONE (0)    : no messages ever printed by the library (default)
 *  - LIBUSB_LOG_LEVEL_ERROR (1)   : error messages are printed to stderr
 *  - LIBUSB_LOG_LEVEL_WARNING (2) : warning and error messages are printed to stderr
 *  - LIBUSB_LOG_LEVEL_INFO (3)    : informational messages are printed to stdout, warning
 *    and error messages are printed to stderr
 *  - LIBUSB_LOG_LEVEL_DEBUG (4)   : debug and informational messages are printed to stdout,
 *    warnings and errors to stderr
 *)
 
TYPE log_level*= LONGINT;
CONST
	LOG_LEVEL_NONE* = 0;
	LOG_LEVEL_ERROR* = 1;
	LOG_LEVEL_WARNING* = 2;
	LOG_LEVEL_INFO* = 3;
	LEVEL_DEBUG* = 4;


TYPE

 context* = POINTER {UNSAFE}TO RECORD
 END;
 
 device_handle* = POINTER {UNSAFE} TO RECORD
 END;
 
 device* = POINTER {UNSAFE} TO RECORD
 END;
 
 device_descriptor* = RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value \ref libusb_descriptor_type::LIBUSB_DT_DEVICE LIBUSB_DT_DEVICE in this context. *)
  bcdUSB- : Uint16;	(* USB specification release number in binary-coded decimal. A value of 0x0200 indicates USB 2.0, 0x0110 indicates USB 1.1, etc. *)
  bDeviceClass- : Uint8; (* USB-IF class code for the device. See \ref libusb_class_code. *)
  bDeviceSubClass- : Uint8; (* USB-IF subclass code for the device, qualified by the bDeviceClass value *)
  bDeviceProtocol- : Uint8; (* USB-IF protocol code for the device, qualified by the bDeviceClass and bDeviceSubClass values *)
  bMaxPacketSize0- : Uint8; (* Maximum packet size for endpoint 0 *)
  idVendor- : Uint16; (* USB-IF vendor ID *)
  idProduct- : Uint16; (* USB-IF product ID *)
  bcdDevice- : Uint16; (* Device release number in binary-coded decimal *)
  iManufacturer- : Uint8; (* Index of string descriptor describing manufacturer *)
  iProduct- : Uint8; (* Index of string descriptor describing product *)
  iSerialNumber- : Uint8; (* Index of string descriptor containing device serial number *)
  bNumConfigurations- : Uint8; (* Number of possible configurations *) 
 END;

 config_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_CONFIG LIBUSB_DT_CONFIG in this context. *)
  wTotalLength- : Uint16; (* Total length of data returned for this configuration *)
  bNumInterfaces- : Uint8; (* Number of interfaces supported by this configuration *)
  bConfigurationValue- :Uint8; (* Identifier value for this configuration *)
  iConfiguration- : Uint8; (* Index of string descriptor describing this configuration *)
  bmAttributes- : Uint8; (* Configuration characteristics *)
  (*
      Maximum power consumption of the USB device from this bus in this
	 configuration when the device is fully operation. Expressed in units
	 of 2 mA when the device is operating in high-speed mode and in units
	 of 8 mA when the device is operating in super-speed mode. 
  *)
  MaxPower- : Uint8;
  interface- : POINTER {UNSAFE} TO ARRAY OF Interface; (* Array of interfaces supported by this configuration. The length of this array is determined by the bNumInterfaces field. *)
  extra- : POINTER {UNSAFE} TO ARRAY OF CHAR; (* Extra descriptors. If libusb encounters unknown configuration descriptors, it will store them here, should you wish to parse them. *)
  extra_length- : LONGINT; (* Length of the extra descriptors, in bytes. *)
 END;
 
 endpoint_descriptor* = RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_ENDPOINT LIBUSB_DT_ENDPOINT in this context. *)
  bEndpointAddress- : Uint8; (* The address of the endpoint described by this descriptor. Bits 0:3 are the endpoint number. Bits 4:6 are reserved. Bit 7 indicates direction, see libusb_endpoint_direction. *)
 (*
    Attributes which apply to the endpoint when it is configured using
    the bConfigurationValue. Bits 0:1 determine the transfer type and
    correspond to \ref libusb_transfer_type. Bits 2:3 are only used for
    isochronous endpoints and correspond to \ref libusb_iso_sync_type.
    Bits 4:5 are also only used for isochronous endpoints and correspond to
    libusb_iso_usage_type. Bits 6:7 are reserved.
  *)
  bmAttributes- : Uint8;
  wMaxPacketSize- : Uint16; (* Maximum packet size this endpoint is capable of sending/receiving. *)
  bInterval- : Uint8; (* Interval for polling endpoint for data transfers. *)
  bRefresh- : Uint8; (* For audio devices only: the rate at which synchronization feedback is provided. *)
  bSynchAddress- : Uint8; (* For audio devices only: the address if the synch endpoint *)
  extra- : POINTER {UNSAFE} TO ARRAY OF CHAR; (* Extra descriptors. If libusb encounters unknown endpoint descriptors, it will store them here, should you wish to parse them. *)
  extra_length- : LONGINT; (* Length of the extra descriptors, in bytes. *)
 END;

 interface_descriptor* = RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have valuef libusb_descriptor_type::LIBUSB_DT_INTERFACE LIBUSB_DT_INTERFACE in this context. *)
  bInterfaceNumber- : Uint8; (* Number of this interface *)
  bAlternateSetting- : Uint8; (* Value used to select this alternate setting for this interface *)
  bNumEndpoints- : Uint8; (* Number of endpoints used by this interface (excluding the control endpoint). *)
  bInterfaceClass- : Uint8; (* USB-IF class code for this interface. See \ref libusb_class_code. *)
  bInterfaceSubClass- : Uint8; (* USB-IF subclass code for this interface, qualified by the bInterfaceClass value *)
  bInterfaceProtocol- : Uint8; (* USB-IF protocol code for this interface, qualified by the bInterfaceClass and bInterfaceSubClass values *)
  iInterface- : Uint8; (* Index of string descriptor describing this interface *)
  endpoint- : POINTER {UNSAFE} TO ARRAY OF endpoint_descriptor; (* Array of endpoint descriptors. This length of this array is determined by the bNumEndpoints field. *)
  extra- : POINTER {UNSAFE} TO ARRAY OF CHAR; (* Extra descriptors. If libusb encounters unknown interface descriptors, it will store them here, should you wish to parse them. *)
  extra_length- : LONGINT; (* Length of the extra descriptors, in bytes. *)
 END;

 Interface*  = RECORD
  altsetting- : POINTER {UNSAFE} TO ARRAY OF interface_descriptor; (* Array of interface descriptors. The length of this array is determined by the num_altsetting field. *)
  num_altsetting- : LONGINT; (* The number of alternate settings that belong to this interface *)
 END; 
 
 ss_endpoint_companion_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_SS_ENDPOINT_COMPANION in this context. *)
  bMaxBurst- : Uint8; (* The maximum number of packets the endpoint can send or receive as part of a burst. *)
  bmAttributes- : Uint8; (* In bulk EP:	bits 4:0 represents the	maximum	number of streams the	EP supports. In	isochronous EP:	bits 1:0 represents the Mult	- a zero based value that determines the	maximum	number of packets within a service interval *)
  wBytesPerInterval- : Uint16; (* The total number of bytes this EP will transfer every service interval. valid only for periodic EPs. *)
 END;
  
 ss_usb_device_capability_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_DEVICE_CAPABILITY in this context. *)
  bDevCapabilityType- : Uint8; (* Capability type. Will have value libusb_capability_type::LIBUSB_BT_SS_USB_DEVICE_CAPABILITY LIBUSB_BT_SS_USB_DEVICE_CAPABILITY in this context. *)
  bmAttributes- : Uint8; (* Bitmap encoding of supported device level features. A value of one in a bit location indicates a feature is supported; a value of zero indicates it is not supported. See libusb_ss_usb_device_capability_attributes. *)
  wSpeedSupported- : Uint16; (* Bitmap encoding of the speed supported by this device when operating in SuperSpeed mode. See \ref libusb_supported_speed. *)
  bFunctionalitySupport- : Uint8; (* The lowest speed at which all the functionality supported by the device is available to the user. For example if the device supports all its functionality when connected at full speed and above then it sets this value to 1. *)
  bU1DevExitLat- : Uint8; (* U1 Device Exit Latency. *)
  bU2DevExitLat- : Uint16; (* U2 Device Exit Latency. *)
 END;  
 
 bos_dev_capability_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_DEVICE_CAPABILITY in this context. *)
  bDevCapabilityType- : Uint8; (* Device Capability type *)
  dev_capability_data- : Uint8; (* valid C99 code *) (*! SEE libusb.h for more.       Device Capability data (bLength - 3 bytes) *)
 END;

 bos_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_BOS LIBUSB_DT_BOS in this context. *)
  wTotalLength- : Uint16; (* Length of this descriptor and all of its sub descriptors *)
  bNumDeviceCaps-: Uint8; (* The number of separate device capability descriptors in the BOS *)
  (* bNumDeviceCap Device Capability Descriptors *)
  dev_capability- : bos_dev_capability_descriptor; (*! SEE libusb.h for more.    struct libusb_bos_dev_capability_descriptor *dev_capability[] - valid C99 code *)
 END;

 usb_2_0_extension_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_DEVICE_CAPABILITY in this context. *)
  bDevCapabilityType- : Uint8; (* Capability type. Will have value libusb_capability_type::LIBUSB_BT_USB_2_0_EXTENSION LIBUSB_BT_USB_2_0_EXTENSION in this context. *)
  bmAttributes- : Uint32; (* Bitmap encoding of supported device level features. A value of one in a bit location indicates a feature is supported; a value of zero indicates it is not supported. See libusb_usb_2_0_extension_attributes. *)
 END;

 container_id_descriptor* = POINTER {UNSAFE} TO RECORD
  bLength- : Uint8; (* Size of this descriptor (in bytes) *)
  bDescriptorType- : Uint8; (* Descriptor type. Will have value libusb_descriptor_type::LIBUSB_DT_DEVICE_CAPABILITY LIBUSB_DT_DEVICE_CAPABILITY in this context. *)
  bDevCapabilityType- : Uint8; (* Capability type. Will have value libusb_capability_type::LIBUSB_BT_CONTAINER_ID LIBUSB_BT_CONTAINER_ID in this context. *)
  bReserved- : Uint8; (* Reserved field *)
  ContainerID- : ARRAY 16 OF CHAR; (* 128 bit UUID *)
 END; 


(* \ingroup asyncio
 * Setup packet for control transfers. *)
 control_setup* = RECORD

	(* Request type. Bits 0:4 determine recipient, see
	 * \ref libusb_request_recipient. Bits 5:6 determine type, see
	 * \ref libusb_request_type. Bit 7 determines data transfer direction, see
	 * \ref libusb_endpoint_direction.
	 *)
	bmRequestType*: Uint8;

	(* Request. If the type bits of bmRequestType are equal to
	 * \ref libusb_request_type::LIBUSB_REQUEST_TYPE_STANDARD
	 * "LIBUSB_REQUEST_TYPE_STANDARD" then this field refers to
	 * \ref libusb_standard_request. For other cases, use of this field is
	 * application-specific. *)
	bRequest*: Uint8;
	wValue*: Uint16; (* Value. Varies according to request *)
	wIndex*: Uint16; (* Index. Varies according to request, typically used to pass an index  or offset *)
	wLength*: Uint16; (* Number of bytes to transfer *)
   END;

CONST CONTROL_SETUP_SIZE* = SIZEOF(control_setup);

TYPE
 iso_packet_descriptor* =  RECORD
  length* : LONGINT; (* Length of data to request in this packet *)
  actual_data* : LONGINT; (* Amount of data that was actually transferred *)
  status* : LONGINT; (* Status code for this packet *)
 END;
 
 transfer_cb_fn* = PROCEDURE {C} (transfer : transfer); 

 pollfd_added_cb* = PROCEDURE {C} (fd : LONGINT; events : Uint16; user_data : ADDRESS); 

 hotplug_callback_fn* = PROCEDURE{C} (ctx : context; device : device; event : LONGINT; user_data : ADDRESS) : LONGINT; 
 
 transfer* = POINTER {UNSAFE} TO RECORD
  dev_handle* : device_handle; (* Handle of the device that this transfer will be submitted to *)
  flags* : Uint8;
  endpoint* : Uint8; (* Address of the endpoint where this transfer will be sent. *)
  type* : Uint8; (* Type of the endpoint from \ref libusb_transfer_type *)
  timeout* : Uint32; (** Timeout for this transfer in millseconds. A value of 0 indicates no timeout. *)
  (* 
      The status of the transfer. Read-only, and only for use within transfer callback function.
	 If this is an isochronous transfer, this field may read COMPLETED even
	 if there were errors in the frames. Use the
	 libusb_iso_packet_descriptor::status "status" field in each packet
	 to determine if errors occurred. 
   *)
   status* : LONGINT; (* enum libusb_transfer_status status; *)
   length* : LONGINT; (* Length of the data buffer *)
   actual_length* : LONGINT; (* Actual length of data that was transferred. Read-only, and only for use within transfer callback function. Not valid for isochronous endpoint transfers. *)
   callback* : transfer_cb_fn; (* Callback function. This will be invoked when the transfer completes, fails, or is cancelled. *)
   user_data* : ADDRESS; (* User context data to pass to the callback function. *)
   buffer* : POINTER {UNSAFE} TO ARRAY OF CHAR; (* Data buffer *)
   num_iso_packets* : LONGINT; (* Number of isochronous packets. Only used for I/O with isochronous endpoints. *)
   iso_packet_desc* : iso_packet_descriptor; (* Isochronous packet descriptors, for isochronous transfers only. *) (* struct libusb_iso_packet_descriptor iso_packet_desc[] *)
 END;

 pollfd* = POINTER {UNSAFE} TO RECORD
  fd* : LONGINT; (* Numeric file descriptor *)
  events* : Uint16; (* Event flags to poll for from <poll.h>. POLLIN indicates that you should monitor this file descriptor for becoming ready to read from, and POLLOUT indicates that you should monitor this file descriptor for onblocking write readiness. *)
 END;



 version* = POINTER {UNSAFE} TO RECORD
  major* : Uint16; (* Library major version. *)
  minor* : Uint16; (* Library minor version. *)
  micro* : Uint16; (* Library micro version. *)
  nano* : Uint16; (* Library nano version. *)
  rc* : POINTER {UNSAFE}TO ARRAY OF CHAR; (* Library release candidate suffix string, e.g. "-rc4". *)
  describe* : POINTER {UNSAFE} TO ARRAY OF CHAR; (* For ABI compatibility only. *)
 END; 
 
 DeviceList* = POINTER {UNSAFE} TO ARRAY OF device;
 
VAR
 libusb- : ADDRESS;

 init-  : PROCEDURE {C} (VAR ctx : context) : LONGINT;
 exit-  : PROCEDURE {C} (ctx : context);
 set_debug-  : PROCEDURE {C} (ctx : context; level=0 : LONGINT);
 get_version-  : PROCEDURE {C} () : version;
 has_capability-  : PROCEDURE {C} (capability : LONGINT) : LONGINT;

 xlibusb_error_name  : PROCEDURE {C} (errorcode : LONGINT) : ADDRESS; (*! wrapped, see below *)

 setlocale-  : PROCEDURE {C} (CONST locale : ARRAY OF CHAR) : LONGINT;  

 xlibusb_strerror  : PROCEDURE {C} (errorcode : LONGINT) : ADDRESS; (*! wrapped, see below *)
 
 get_device_list- : PROCEDURE {C} (ctx : context; VAR list : DeviceList) : LONGINT;   
 free_device_list- : PROCEDURE {C} (list : DeviceList; unref_devices : LONGINT);
 ref_device- : PROCEDURE {C} (dev : device) : device;
 unref_device- : PROCEDURE {C} (dev : device);
 get_configuration- : PROCEDURE {C} (dev : device_handle; VAR config : LONGINT) : LONGINT;
 get_device_descriptor- : PROCEDURE {C} (dev : device; VAR desc : device_descriptor) : LONGINT; 
 get_active_config_descriptor- : PROCEDURE {C} (dev : device; VAR desc : config_descriptor) : LONGINT; 
 get_config_descriptor-  : PROCEDURE {C} (dev : device; config_index : Uint8; VAR config : config_descriptor) : LONGINT;
 get_config_descriptor_by_value-  : PROCEDURE {C} (dev : device; bConfigurationValue : Uint8; VAR config : config_descriptor) : LONGINT;
 free_config_descriptor-  : PROCEDURE {C} (config : config_descriptor);
 get_ss_endpoint_companion_descriptor-  : PROCEDURE {C} (ctx : context; endpoint : endpoint_descriptor; VAR ep_comp : ss_endpoint_companion_descriptor) : LONGINT;
 free_ss_endpoint_companion_descriptor-: PROCEDURE {C} (ep_comp: ss_endpoint_companion_descriptor); 
 get_bos_descriptor-  : PROCEDURE {C} (dev : device_handle; VAR bos : bos_descriptor) : LONGINT;
 free_bos_descriptor-  : PROCEDURE {C} (config : bos_descriptor);
 get_usb_2_0_extension_descriptor-  : PROCEDURE {C} (ctx : context; dev_cap : bos_dev_capability_descriptor; VAR usb_2_0_extension : usb_2_0_extension_descriptor) : LONGINT;
 free_usb_2_0_extension_descriptor-  : PROCEDURE {C} (usb_2_0_extension : usb_2_0_extension_descriptor);
 get_ss_usb_device_capability_descriptor-  : PROCEDURE {C} (ctx : context; dv_cap : bos_dev_capability_descriptor; VAR ss_usb_device_cap : ss_usb_device_capability_descriptor) : LONGINT;
 free_ss_usb_device_capability_descriptor-  : PROCEDURE {C} (ss_usb_device_cap : ss_usb_device_capability_descriptor);
 get_container_id_descriptor-  : PROCEDURE {C} (ctx : context; dev_cap : bos_dev_capability_descriptor; VAR container_id : container_id_descriptor) : LONGINT;
 free_container_id_descriptor-  : PROCEDURE {C} (container_id : container_id_descriptor);
 get_bus_number-  : PROCEDURE {C} (dev : device) : Uint8;
 get_port_number-  : PROCEDURE {C} (dev : device) : Uint8;
 get_port_numbers-  : PROCEDURE {C} (dev : device; port_numbers : ADDRESS; port_numbers_len : LONGINT) : LONGINT;
 get_port_path-  : PROCEDURE {C} (ctx : context; dev : device; path : ADDRESS; path_length : LONGINT) : LONGINT;
 get_parent-  : PROCEDURE {C} (dev : device) : device;
 get_device_address-  : PROCEDURE {C} (dev : device) : Uint8;
 get_device_speed-  : PROCEDURE {C} (dev : device) : LONGINT;
 get_max_packet_size-  : PROCEDURE {C} (dev : device; endpoint : Uint8) : LONGINT;
 get_max_iso_packet_size-  : PROCEDURE {C} (dev : device; endpoint : Uint8) : LONGINT;
 open- : PROCEDURE {C} (dev : device;  VAR handle : device_handle) : LONGINT;
 close- : PROCEDURE {C} (dev_handle : device_handle);
 get_device- : PROCEDURE {C} (dev_handle : device_handle) : device;	
 set_configuration- : PROCEDURE {C} (dev : device_handle; configuration : LONGINT) : LONGINT;
 claim_interface- : PROCEDURE {C} (dev : device_handle; interface_number : LONGINT) : LONGINT;
 release_interface- : PROCEDURE {C} (dev : device_handle; interface_number : LONGINT) : LONGINT;
 open_device_with_vid_pid- : PROCEDURE {C} (ctx : context; vendor_id, product_id : LONGINT) : device_handle;
 set_interface_alt_setting- : PROCEDURE {C} (dev : device_handle; interface_number, alternate_setting : LONGINT) : LONGINT;
 clear_halt- : PROCEDURE {C} (dev : device_handle; endpoint : Uint8) : LONGINT;
 reset_device- : PROCEDURE {C} (dev : device_handle) : LONGINT;
 alloc_streams- : PROCEDURE {C} (dev : device_handle; num_streams : LONGINT; endpoints : ADDRESS; num_endpoints : LONGINT) : LONGINT;
 free_streams- : PROCEDURE {C} (dev : device_handle; endpoints : ADDRESS; num_endpoints : LONGINT) : LONGINT;
 kernel_driver_active- : PROCEDURE {C} (dev : device_handle; interface_number : LONGINT) : LONGINT;
 detach_kernel_driver- : PROCEDURE {C} (dev : device_handle; interface_number : LONGINT) : LONGINT;
 attach_kernel_driver- : PROCEDURE {C} (dev : device_handle; interface_number : LONGINT) : LONGINT;
 set_auto_detach_kernel_driver- : PROCEDURE {C} (dev : device_handle; enable : LONGINT) : LONGINT;
 alloc_transfer- : PROCEDURE {C} (iso_packets : LONGINT) : transfer;
 submit_transfer- : PROCEDURE {C} (transfer: transfer) : LONGINT;
 cancel_transfer- : PROCEDURE {C} (transfer: transfer) : LONGINT;
 free_transfer- : PROCEDURE {C} (transfer: transfer);
 transfer_set_stream_id- : PROCEDURE {C} (transfer: transfer; stream_id : LONGINT);
 transfer_get_stream_id- : PROCEDURE {C} (transfer: transfer) : LONGINT;
 control_transfer- : PROCEDURE {C} (dev_handle : device_handle; request_type, bRequest : Uint8; wValue, wIndex : Uint16; data : ADDRESS; wLength : Uint16; timeout : LONGINT) : LONGINT;
 bulk_transfer- : PROCEDURE {C} (dev_handle : device_handle; endpoint : LONGINT; data : ADDRESS; length : LONGINT; VAR actual_length : LONGINT; timeout : LONGINT) : LONGINT;
 interrupt_transfer- : PROCEDURE {C} (dev_handle : device_handle; endpoint : LONGINT; data : ADDRESS; length : LONGINT; VAR actual_length : LONGINT; timeout : LONGINT) : LONGINT;
 get_string_descriptor_ascii- : PROCEDURE {C} (dev : device_handle; desc_index : Uint8; data : ADDRESS ; length : LONGINT) : LONGINT;
 try_lock_events- : PROCEDURE {C} (ctx : context) : LONGINT;
 lock_events- : PROCEDURE {C} (ctx : context);
 unlock_events- : PROCEDURE {C} (ctx : context); 
 event_handling_ok- : PROCEDURE {C} (ctx : context) : LONGINT;
 event_handler_active- : PROCEDURE {C} (ctx : context) : LONGINT; 
 interrupt_event_handler- : PROCEDURE {C} (ctx : context);
 unlock_event_waiters- : PROCEDURE {C} (ctx : context);
 lock_event_waiters- : PROCEDURE {C} (ctx : context);
 wait_for_event- : PROCEDURE {C} (ctx : context; VAR tv : u.Timeval) : LONGINT;
 wait_handle_events_timeout- : PROCEDURE {C} (ctx : context; VAR tv : u.Timeval) : LONGINT;
 handle_events_timeout_completed- : PROCEDURE {C} (ctx : context; VAR tv : u.Timeval; VAR completed : LONGINT) : LONGINT;
 handle_events- : PROCEDURE {C} (ctx : context) : LONGINT;
 handle_events_completed- : PROCEDURE {C} (ctx : context; VAR completed : LONGINT) : LONGINT;
 handle_events_locked- : PROCEDURE {C} (ctx : context; VAR tv : u.Timeval) : LONGINT;
 pollfds_handle_timeouts- : PROCEDURE {C} (ctx : context) : LONGINT;
 get_next_timeout- : PROCEDURE {C} (ctx : context; VAR tv : u.Timeval) : LONGINT;
 pollfd_removed_cb- : PROCEDURE {C} (fd : LONGINT; user_data : ADDRESS);
 get_pollfds- : PROCEDURE {C} (ctx : context) : pollfd; (*! const struct pollfd ** LIBUSB_CALL get_pollfds(	context *ctx); *)
 free_pollfds- : PROCEDURE {C} (VAR pollfds : pollfd);
 set_pollfd_notifiers- : PROCEDURE {C} (ctx : context; added_cb, removed_cb : pollfd_added_cb; user_data : ADDRESS);
 hotplug_register_callback- : PROCEDURE {C} (ctx : context; events, flags : LONGINT; vendor_id, product_id, dev_class : LONGINT; cb_fn : hotplug_callback_fn; user_data : ADDRESS; handle : LONGINT) : LONGINT;
 hotplug_deregister_callback- : PROCEDURE {C} (ctx : context; handle : LONGINT);

PROCEDURE Cleanup(); 
BEGIN
 IF libusb # 0 THEN u.Dlclose(libusb) END;
END Cleanup;

(** Get string from address  *)
PROCEDURE GetStringFromAddr* (adr: ADDRESS): POINTER TO ARRAY OF CHAR;
VAR  sadr: ADDRESS;
	cnt: LONGINT;
	ch: CHAR;
	s: POINTER TO ARRAY OF CHAR;
BEGIN
	IF adr # NIL THEN
		(* find length  *)
		sadr := adr;
		cnt  := 0;		
		SYSTEM.GET(sadr,ch);
		WHILE (ch # 0X) DO  INC(cnt); INC(sadr); SYSTEM.GET(sadr,ch); END;
		
		(* then, copy string *)
		NEW(s, cnt+1);
		SYSTEM.MOVE(adr, ADDRESSOF(s[0]), cnt);
	END;	
	RETURN s;
END GetStringFromAddr;

(* wrapper *)
PROCEDURE strerror*(errorcode: LONGINT): POINTER TO ARRAY OF CHAR;
VAR a: ADDRESS;
	s: POINTER TO ARRAY OF CHAR;
BEGIN
	a := xlibusb_strerror(errorcode);
	s := GetStringFromAddr(a);
	RETURN s;
END strerror;

(* wrapper *)
PROCEDURE error_name*(errorcode: LONGINT): POINTER TO ARRAY OF CHAR;
VAR a: ADDRESS;
	s: POINTER TO ARRAY OF CHAR;
BEGIN
	a := xlibusb_error_name(errorcode);
	s := GetStringFromAddr(a);
	RETURN s;
END error_name;

BEGIN
 libusb := u.Dlopen(libusbname, 2);
 ASSERT(libusb # 0, 100);
 m.InstallTermHandler(Cleanup);
 
 u.Dlsym(libusb, "libusb_init", ADDRESSOF(init));
 u.Dlsym(libusb, "libusb_exit", ADDRESSOF(exit));
 u.Dlsym(libusb, "libusb_set_debug", ADDRESSOF(set_debug));
 u.Dlsym(libusb, "libusb_get_version", ADDRESSOF(get_version));
 u.Dlsym(libusb, "libusb_has_capability", ADDRESSOF(has_capability));
 u.Dlsym(libusb, "libusb_error_name", ADDRESSOF(xlibusb_error_name)); (*! wrapped *)
 u.Dlsym(libusb, "libusb_setlocale", ADDRESSOF(setlocale));
 u.Dlsym(libusb, "libusb_strerror", ADDRESSOF(xlibusb_strerror)); (*! wrapped *)
 u.Dlsym(libusb, "libusb_get_device_list", ADDRESSOF(get_device_list));
 u.Dlsym(libusb, "libusb_free_device_list", ADDRESSOF(free_device_list));
 u.Dlsym(libusb, "libusb_ref_device", ADDRESSOF(ref_device));  
 u.Dlsym(libusb, "libusb_unref_device", ADDRESSOF(unref_device)); 
 u.Dlsym(libusb, "libusb_get_configuration", ADDRESSOF(get_configuration));
 u.Dlsym(libusb, "libusb_get_device_descriptor", ADDRESSOF(get_device_descriptor)); 
 u.Dlsym(libusb, "libusb_get_active_config_descriptor", ADDRESSOF(get_active_config_descriptor));
 u.Dlsym(libusb, "libusb_get_config_descriptor", ADDRESSOF(get_config_descriptor));
 u.Dlsym(libusb, "libusb_get_config_descriptor_by_value", ADDRESSOF(get_config_descriptor_by_value));
 u.Dlsym(libusb, "libusb_free_config_descriptor", ADDRESSOF(free_config_descriptor));
 u.Dlsym(libusb, "libusb_get_ss_endpoint_companion_descriptor", ADDRESSOF(get_ss_endpoint_companion_descriptor));
 u.Dlsym(libusb, "libusb_free_ss_endpoint_companion_descriptor", ADDRESSOF( free_ss_endpoint_companion_descriptor));
 u.Dlsym(libusb, "libusb_get_bos_descriptor", ADDRESSOF(get_bos_descriptor));
 u.Dlsym(libusb, "libusb_free_bos_descriptor", ADDRESSOF(free_bos_descriptor));
 u.Dlsym(libusb, "libusb_get_usb_2_0_extension_descriptor", ADDRESSOF(get_usb_2_0_extension_descriptor));
 u.Dlsym(libusb, "libusb_free_usb_2_0_extension_descriptor", ADDRESSOF(free_usb_2_0_extension_descriptor));
 u.Dlsym(libusb, "libusb_get_ss_usb_device_capability_descriptor", ADDRESSOF(get_ss_usb_device_capability_descriptor));
 u.Dlsym(libusb, "libusb_free_ss_usb_device_capability_descriptor", ADDRESSOF(free_ss_usb_device_capability_descriptor));
 u.Dlsym(libusb, "libusb_get_container_id_descriptor", ADDRESSOF(get_container_id_descriptor));
 u.Dlsym(libusb, "libusb_free_container_id_descriptor", ADDRESSOF(free_container_id_descriptor));
 u.Dlsym(libusb, "libusb_get_bus_number", ADDRESSOF(get_bus_number));
 u.Dlsym(libusb, "libusb_get_port_number", ADDRESSOF(get_port_number));
 u.Dlsym(libusb, "libusb_get_port_numbers", ADDRESSOF(get_port_numbers));
 u.Dlsym(libusb, "libusb_get_port_path", ADDRESSOF(get_port_path));
 u.Dlsym(libusb, "libusb_get_parent", ADDRESSOF(get_parent));
 u.Dlsym(libusb, "libusb_get_device_address", ADDRESSOF(get_device_address));
 u.Dlsym(libusb, "libusb_get_device_speed", ADDRESSOF(get_device_speed));
 u.Dlsym(libusb, "libusb_get_max_packet_size", ADDRESSOF(get_max_packet_size));
 u.Dlsym(libusb, "libusb_get_max_iso_packet_size", ADDRESSOF(get_max_iso_packet_size));
 u.Dlsym(libusb, "libusb_open", ADDRESSOF(open));
 u.Dlsym(libusb, "libusb_close", ADDRESSOF(close));
 u.Dlsym(libusb, "libusb_get_device", ADDRESSOF(get_device));
 u.Dlsym(libusb, "libusb_set_configuration", ADDRESSOF(set_configuration));
 u.Dlsym(libusb, "libusb_claim_interface", ADDRESSOF(claim_interface));
 u.Dlsym(libusb, "libusb_release_interface", ADDRESSOF(release_interface));
 u.Dlsym(libusb, "libusb_open_device_with_vid_pid", ADDRESSOF(open_device_with_vid_pid));
 u.Dlsym(libusb, "libusb_set_interface_alt_setting", ADDRESSOF(set_interface_alt_setting));
 u.Dlsym(libusb, "libusb_clear_halt", ADDRESSOF(clear_halt));
 u.Dlsym(libusb, "libusb_reset_device", ADDRESSOF(reset_device));
 u.Dlsym(libusb, "libusb_alloc_streams", ADDRESSOF(alloc_streams));  
 u.Dlsym(libusb, "libusb_free_streams", ADDRESSOF(free_streams));
 u.Dlsym(libusb, "libusb_kernel_driver_active", ADDRESSOF(kernel_driver_active));  
 u.Dlsym(libusb, "libusb_detach_kernel_driver", ADDRESSOF(detach_kernel_driver));
 u.Dlsym(libusb, "libusb_attach_kernel_driver", ADDRESSOF(attach_kernel_driver));
 u.Dlsym(libusb, "libusb_set_auto_detach_kernel_driver", ADDRESSOF(set_auto_detach_kernel_driver));   
 u.Dlsym(libusb, "libusb_alloc_transfer", ADDRESSOF(alloc_transfer)); 
 u.Dlsym(libusb, "libusb_submit_transfer", ADDRESSOF(submit_transfer)); 
 u.Dlsym(libusb, "libusb_cancel_transfer", ADDRESSOF(cancel_transfer)); 
 u.Dlsym(libusb, "libusb_free_transfer", ADDRESSOF(free_transfer)); 
 u.Dlsym(libusb, "libusb_transfer_set_stream_id", ADDRESSOF(transfer_set_stream_id)); 
 u.Dlsym(libusb, "libusb_transfer_get_stream_id", ADDRESSOF(transfer_get_stream_id)); 
 u.Dlsym(libusb, "libusb_control_transfer", ADDRESSOF(control_transfer));
 u.Dlsym(libusb, "libusb_bulk_transfer", ADDRESSOF(bulk_transfer)); 
 u.Dlsym(libusb, "libusb_interrupt_transfer", ADDRESSOF(interrupt_transfer));
 u.Dlsym(libusb, "libusb_get_string_descriptor_ascii", ADDRESSOF(get_string_descriptor_ascii));
 u.Dlsym(libusb, "libusb_try_lock_events", ADDRESSOF(try_lock_events));
 u.Dlsym(libusb, "libusb_lock_events", ADDRESSOF(lock_events));
 u.Dlsym(libusb, "libusb_unlock_events", ADDRESSOF(unlock_events)); 
END libusb.

SystemTools.Free libusb ~