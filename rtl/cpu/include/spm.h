/*
 -- ============================================================================
 -- FILE NAME	: spm.h
 -- DESCRIPTION : スクラッチパッドメモリヘッダ
 -- ----------------------------------------------------------------------------
 -- Revision  Date		  Coding_by	 Comment
 -- 1.0.0	  2011/06/27  suito		 仟�ﾗ�撹
 -- ============================================================================
*/

`ifndef __SPM_HEADER__
	`define __SPM_HEADER__			  // インクル�`ドガ�`ド

/*
 * ‐SPMのサイズについて／
 * ?SPMのサイズを�筝�するには、
 *	 SPM_SIZE、SPM_DEPTH、SPM_ADDR_W、SpmAddrBus、SpmAddrLocを�筝�して和さい。
 * ?SPM_SIZEはSPMのサイズを協�xしています。
 * ?SPM_DEPTHはSPMの侮さを協�xしています。
 *	 SPMの嫌は児云議に32bit��4Byte��耕協なので、
 *	 SPM_DEPTHはSPM_SIZEを4で護った�､砲覆蠅泙后�
 * ?SPM_ADDR_WはSPMのアドレス嫌を協�xしており、
 *	 SPM_DEPTHをlog2した�､砲覆蠅泙后�
 * ?SpmAddrBusとSpmAddrLocはSPM_ADDR_Wのバスです。
 *	 SPM_ADDR_W-1:0として和さい。
 *
 * ‐SPMのサイズの箭／
 * ?SPMのサイズが16384Byte��16KB��の��栽、
 *	 SPM_DEPTHは16384‖4で4096
 *	 SPM_ADDR_Wはlog2(4096)で12となります。
 */

	`define SPM_SIZE   16384 // SPMのサイズ
	`define SPM_DEPTH  4096	 // SPMの侮さ
	`define SPM_ADDR_W 12	 // アドレス嫌
	`define SpmAddrBus 11:0	 // アドレスバス
	`define SpmAddrLoc 11:0	 // アドレスの了崔

`endif

