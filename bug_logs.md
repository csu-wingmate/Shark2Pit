## libcoap(CoAP): heap-use-after-free
```
=================================================================
==502==ERROR: AddressSanitizer: heap-use-after-free on address 0x60d0001486f8 at pc 0x0000005f167b bp 0x7fca8b5fbdc0 sp 0x7fca8b5fbdb8
READ of size 8 at 0x60d0001486f8 thread T2
    #0 0x5f167a in coap_option_iterator_init /root/libcoap/src/coap_option.c:120:3
    #1 0x5f28f7 in coap_check_option /root/libcoap/src/coap_option.c:206:3
    #2 0x4e68b2 in coap_get_block_b /root/libcoap/src/coap_block.c:70:24
    #3 0x4feccd in coap_add_data_large_response_lkd /root/libcoap/src/coap_block.c:1338:9
    #4 0x4feaf9 in coap_add_data_large_response /root/libcoap/src/coap_block.c:1300:9
    #5 0x4d3a07 in hnd_get_index /root/libcoap/examples/coap-server.c:283:3
    #6 0x5e5d87 in handle_request /root/libcoap/src/coap_net.c:3876:5
    #7 0x5c4186 in coap_dispatch /root/libcoap/src/coap_net.c:4682:7
    #8 0x5be840 in coap_read_session /root/libcoap/src/coap_net.c:2507:15
    #9 0x5d0092 in coap_io_do_epoll_lkd /root/libcoap/src/coap_net.c:2799:13
    #10 0x5975b8 in coap_io_process_with_fds_lkd /root/libcoap/src/coap_io.c:2126:5
    #11 0x6e7d55 in coap_io_process_worker_thread /root/libcoap/src/coap_threadsafe.c:131:14
    #12 0x7fca8f970608 in start_thread /build/glibc-B3wQXB/glibc-2.31/nptl/pthread_create.c:477:8
    #13 0x7fca8f719352 in clone /build/glibc-B3wQXB/glibc-2.31/misc/../sysdeps/unix/sysv/linux/x86_64/clone.S:95

0x60d0001486f8 is located 72 bytes inside of 144-byte region [0x60d0001486b0,0x60d000148740)
freed by thread T1 here:
    #0 0x496fed in free (/root/libcoap/examples/coap-server+0x496fed)
    #1 0x5bf23a in coap_read_session /root/libcoap/src/coap_net.c:2519:13
    #2 0x5d0092 in coap_io_do_epoll_lkd /root/libcoap/src/coap_net.c:2799:13
    #3 0x5975b8 in coap_io_process_with_fds_lkd /root/libcoap/src/coap_io.c:2126:5
    #4 0x6e7d55 in coap_io_process_worker_thread /root/libcoap/src/coap_threadsafe.c:131:14
    #5 0x7fca8f970608 in start_thread /build/glibc-B3wQXB/glibc-2.31/nptl/pthread_create.c:477:8

previously allocated by thread T2 here:
    #0 0x49726d in malloc (/root/libcoap/examples/coap-server+0x49726d)
    #1 0x60f61c in coap_pdu_init /root/libcoap/src/coap_pdu.c:119:9
    #2 0x5be924 in coap_read_session /root/libcoap/src/coap_net.c:2548:36
    #3 0x5d0092 in coap_io_do_epoll_lkd /root/libcoap/src/coap_net.c:2799:13
    #4 0x5975b8 in coap_io_process_with_fds_lkd /root/libcoap/src/coap_io.c:2126:5
    #5 0x6e7d55 in coap_io_process_worker_thread /root/libcoap/src/coap_threadsafe.c:131:14
    #6 0x7fca8f970608 in start_thread /build/glibc-B3wQXB/glibc-2.31/nptl/pthread_create.c:477:8

Thread T2 created by T0 here:
    #0 0x48201a in pthread_create (/root/libcoap/examples/coap-server+0x48201a)
    #1 0x6e79cd in coap_io_process_configure_threads /root/libcoap/src/coap_threadsafe.c:161:9
    #2 0x5980b0 in coap_io_process_loop_lkd /root/libcoap/src/coap_io.c:2190:10
    #3 0x597f92 in coap_io_process_loop /root/libcoap/src/coap_io.c:2174:9
    #4 0x4cc12a in main /root/libcoap/examples/coap-server.c:2666:8
    #5 0x7fca8f61e082 in __libc_start_main /build/glibc-B3wQXB/glibc-2.31/csu/../csu/libc-start.c:308:16

Thread T1 created by T0 here:
    #0 0x48201a in pthread_create (/root/libcoap/examples/coap-server+0x48201a)
    #1 0x6e79cd in coap_io_process_configure_threads /root/libcoap/src/coap_threadsafe.c:161:9
    #2 0x5980b0 in coap_io_process_loop_lkd /root/libcoap/src/coap_io.c:2190:10
    #3 0x597f92 in coap_io_process_loop /root/libcoap/src/coap_io.c:2174:9
    #4 0x4cc12a in main /root/libcoap/examples/coap-server.c:2666:8
    #5 0x7fca8f61e082 in __libc_start_main /build/glibc-B3wQXB/glibc-2.31/csu/../csu/libc-start.c:308:16

SUMMARY: AddressSanitizer: heap-use-after-free /root/libcoap/src/coap_option.c:120:3 in coap_option_iterator_init
Shadow bytes around the buggy address:
  0x0c1a80021080: fa fa fa fa fa fa fa fa fd fd fd fd fd fd fd fd
  0x0c1a80021090: fd fd fd fd fd fd fd fd fd fd fa fa fa fa fa fa
  0x0c1a800210a0: fa fa fd fd fd fd fd fd fd fd fd fd fd fd fd fd
  0x0c1a800210b0: fd fd fd fd fa fa fa fa fa fa fa fa fd fd fd fd
  0x0c1a800210c0: fd fd fd fd fd fd fd fd fd fd fd fd fd fd fa fa
=>0x0c1a800210d0: fa fa fa fa fa fa fd fd fd fd fd fd fd fd fd[fd]
  0x0c1a800210e0: fd fd fd fd fd fd fd fd fa fa fa fa fa fa fa fa
  0x0c1a800210f0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c1a80021100: 00 00 fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c1a80021110: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c1a80021120: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
Shadow byte legend (one shadow byte represents 8 application bytes):
  Addressable:           00
  Partially addressable: 01 02 03 04 05 06 07
  Heap left redzone:       fa
  Freed heap region:       fd
  Stack left redzone:      f1
  Stack mid redzone:       f2
  Stack right redzone:     f3
  Stack after return:      f5
  Stack use after scope:   f8
  Global redzone:          f9
  Global init order:       f6
  Poisoned by user:        f7
  Container overflow:      fc
  Array cookie:            ac
  Intra object redzone:    bb
  ASan internal:           fe
  Left alloca redzone:     ca
  Right alloca redzone:    cb
  Shadow gap:              cc
==502==ABORTING
```
## libcoap(CoAP): use-of-uninitialized-value
```
==431==WARNING: MemorySanitizer: use-of-uninitialized-value
    #0 0x55add74122e0 in coap_digest_setup /root/libcoap/src/coap_gnutls.c:3013:1
    #1 0x55add732b2a9 in coap_add_data_large_internal /root/libcoap/src/coap_block.c:849:36
    #2 0x55add732e675 in coap_add_data_large_response_lkd /root/libcoap/src/coap_block.c:1403:8
    #3 0x55add7319ecb in hnd_get_index /root/libcoap/examples/coap-server.c:289:3
    #4 0x55add7385048 in handle_request /root/libcoap/src/coap_net.c 
    #5 0x55add7377102 in coap_dispatch /root/libcoap/src/coap_net.c:4783:7
    #6 0x55add737446b in coap_read_session /root/libcoap/src/coap_net.c:2552:15
    #7 0x55add737c48b in coap_io_do_epoll_lkd /root/libcoap/src/coap_net.c:2844:13
    #8 0x55add73608e1 in coap_io_process_with_fds_lkd /root/libcoap/src/coap_io.c:2154:5
    #9 0x55add73150d4 in main /root/libcoap/examples/coap-server.c:2741:20
    #10 0x7f83f9ad71c9  (/lib/x86_64-linux-gnu/libc.so.6+0x2a1c9) (BuildId: 282c2c16e7b6600b0b22ea0c99010d2795752b5f)
    #11 0x7f83f9ad728a in __libc_start_main (/lib/x86_64-linux-gnu/libc.so.6+0x2a28a) (BuildId: 282c2c16e7b6600b0b22ea0c99010d2795752b5f) 
    #12 0x55add7276a24 in _start (/root/libcoap/build/coap-server+0x36a24) (BuildId: 90df580774734d63011f3d24f29f051bc1e66bd3)

  Uninitialized value was stored to memory at
    #0 0x55add74122d9 in coap_digest_setup /root/libcoap/src/coap_gnutls.c:3009:7
    #1 0x55add732b2a9 in coap_add_data_large_internal /root/libcoap/src/coap_block.c:849:36
    #2 0x55add732e675 in coap_add_data_large_response_lkd /root/libcoap/src/coap_block.c:1403:8
    #3 0x55add7319ecb in hnd_get_index /root/libcoap/examples/coap-server.c:289:3
.c:3007:3

SUMMARY: MemorySanitizer: use-of-uninitialized-value /root/libcoap/src/coap_gnutls.c:3013:1 in coap_digest_setup
```
## bacnet-stack(BACnet): use-of-uninitialized-value
```
BACnet Server Demo
BACnet Stack Version 1.4.1
BACnet Device ID: 260001
Max APDU: 1476
Created object analog-input-1
Created object analog-output-1
Created object analog-value-1
Created object binary-input-1
Created object binary-output-1
Created object binary-value-1
Created object calendar-1
Created object multi-state-input-1
Created object multi-state-output-1
Created object program-1
Created object multi-state-value-1
Created object life-safety-point-1
Created object life-safety-zone-1
Created object load-control-1
Created object structured-view-1
Created object bitstring-value-1
Created object characterstring-value-1
Created object integer-value-1
Created object channel-1
Created object lighting-output-1
Created object binary-lighting-output-1
Created object color-1
Created object color-temperature-1
BACnet Device Name: SimpleServer
RP: Unable to decode Request!
RP: Sending Reject!
SubscribeCOV: Unable to decode Request!
==126==WARNING: MemorySanitizer: use-of-uninitialized-value
    #0 0x684604 in bacnet_unsigned_length /root/bacnet-stack/src/bacnet/bacint.c:261:9
    #1 0x6607d4 in encode_application_enumerated /root/bacnet-stack/src/bacnet/bacdcode.c:3383:15
    #2 0x680df2 in bacerror_encode_apdu /root/bacnet-stack/src/bacnet/bacerror.c:58:11
    #3 0x545404 in handler_cov_subscribe /root/bacnet-stack/src/bacnet/basic/service/h_cov.c:870:24
    #4 0x54002d in apdu_handler /root/bacnet-stack/src/bacnet/basic/service/h_apdu.c
    #5 0x4a2a37 in npdu_handler /root/bacnet-stack/src/bacnet/basic/npdu/h_npdu.c:253:21
    #6 0x4965bb in main /root/bacnet-stack/apps/server/main.c:408:13
    #7 0x7f13ed022082 in __libc_start_main /build/glibc-B3wQXB/glibc-2.31/csu/../csu/libc-start.c:308:16
    #8 0x41c3cd in _start (/root/bacnet-stack/build/server+0x41c3cd)

  Uninitialized value was created by an allocation of 'cov_data' in the stack frame of function 'handler_cov_subscribe'
    #0 0x544780 in handler_cov_subscribe /root/bacnet-stack/src/bacnet/basic/service/h_cov.c:808

SUMMARY: MemorySanitizer: use-of-uninitialized-value /root/bacnet-stack/src/bacnet/bacint.c:261:9 in bacnet_unsigned_length
Exiting
```
## OpEner(EtherNet): undefined-behavior
```
/root/OpENer/source/src/enet_encap/endianconv.c:101:76: runtime error: left shift of 159 by 24 places cannot be represented in type 'int'   
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior /root/OpENer/source/src/enet_encap/endianconv.c:101:76 in
```
## open62541(OPC UA): undefined-behavior
```
/root/open62541/src/ua_types_encoding_binary.c:241:5: runtime error: applying non-zero offset 4 to null pointer
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior /root/open62541/src/ua_types_encoding_binary.c:241:5 in
/root/open62541/src/ua_types_encoding_binary.c:248:14: runtime error: applying non-zero offset 4 to null pointer
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior /root/open62541/src/ua_types_encoding_binary.c:248:14 in
```
