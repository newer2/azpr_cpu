/*
 -- ============================================================================
 -- FILE NAME	: bus_if.v
 -- DESCRIPTION : バスインタフェ�`ス
 -- ----------------------------------------------------------------------------
 -- Revision  Date		  Coding_by	 Comment
 -- 1.0.0	  2011/06/27  suito		 仟�ﾗ�撹
 -- ============================================================================
*/

/********** 慌宥ヘッダファイル **********/
`include "nettype.h"
`include "global_config.h"
`include "stddef.h"

/********** ���eヘッダファイル **********/
`include "cpu.h"
`include "bus.h"

/********** モジュ�`ル **********/
module bus_if (
	/********** クロック & リセット **********/
	input  wire				   clk,			   // クロック
	input  wire				   reset,		   // 掲揖豚リセット
	/********** パイプライン崙囮佚催 **********/
	input  wire				   stall,		   // スト�`ル
	input  wire				   flush,		   // フラッシュ佚催
	output reg				   busy,		   // ビジ�`佚催
	/********** CPUインタフェ�`ス **********/
	input  wire [`WordAddrBus] addr,		   // アドレス
	input  wire				   as_,			   // アドレス嗤��
	input  wire				   rw,			   // �iみ����き
	input  wire [`WordDataBus] wr_data,		   // ��き�zみデ�`タ
	output reg	[`WordDataBus] rd_data,		   // �iみ竃しデ�`タ
	/********** SPMインタフェ�`ス **********/
	input  wire [`WordDataBus] spm_rd_data,	   // �iみ竃しデ�`タ
	output wire [`WordAddrBus] spm_addr,	   // アドレス
	output reg				   spm_as_,		   // アドレスストロ�`ブ
	output wire				   spm_rw,		   // �iみ����き
	output wire [`WordDataBus] spm_wr_data,	   // ��き�zみデ�`タ
	/********** バスインタフェ�`ス **********/
	input  wire [`WordDataBus] bus_rd_data,	   // �iみ竃しデ�`タ
	input  wire				   bus_rdy_,	   // レディ
	input  wire				   bus_grnt_,	   // バスグラント
	output reg				   bus_req_,	   // バスリクエスト
	output reg	[`WordAddrBus] bus_addr,	   // アドレス
	output reg				   bus_as_,		   // アドレスストロ�`ブ
	output reg				   bus_rw,		   // �iみ����き
	output reg	[`WordDataBus] bus_wr_data	   // ��き�zみデ�`タ
);

	/********** 坪何佚催 **********/
	reg	 [`BusIfStateBus]	   state;		   // バスインタフェ�`スの彜�B
	reg	 [`WordDataBus]		   rd_buf;		   // �iみ竃しバッファ
	wire [`BusSlaveIndexBus]   s_index;		   // バススレ�`ブインデックス

	/********** バススレ�`ブのインデックス **********/
	assign s_index	   = addr[`BusSlaveIndexLoc];

	/********** 竃薦のアサイン **********/
	assign spm_addr	   = addr;
	assign spm_rw	   = rw;
	assign spm_wr_data = wr_data;
						 
	/********** メモリアクセスの崙囮 **********/
	always @(*) begin
		/* デフォルト�� */
		rd_data	 = `WORD_DATA_W'h0;
		spm_as_	 = `DISABLE_;
		busy	 = `DISABLE;
		/* バスインタフェ�`スの彜�B */
		case (state)
			`BUS_IF_STATE_IDLE	 : begin // アイドル
				/* メモリアクセス */
				if ((flush == `DISABLE) && (as_ == `ENABLE_)) begin
					/* アクセス枠の�x�k */
					if (s_index == `BUS_SLAVE_1) begin // SPMへアクセス
						if (stall == `DISABLE) begin // スト�`ル�k伏のチェック
							spm_as_	 = `ENABLE_;
							if (rw == `READ) begin // �iみ竃しアクセス
								rd_data	 = spm_rd_data;
							end
						end
					end else begin					   // バスへアクセス
						busy	 = `ENABLE;
					end
				end
			end
			`BUS_IF_STATE_REQ	 : begin // バスリクエスト
				busy	 = `ENABLE;
			end
			`BUS_IF_STATE_ACCESS : begin // バスアクセス
				/* レディ棋ち */
				if (bus_rdy_ == `ENABLE_) begin // レディ欺彭
					if (rw == `READ) begin // �iみ竃しアクセス
						rd_data	 = bus_rd_data;
					end
				end else begin					// レディ隆欺彭
					busy	 = `ENABLE;
				end
			end
			`BUS_IF_STATE_STALL	 : begin // スト�`ル
				if (rw == `READ) begin // �iみ竃しアクセス
					rd_data	 = rd_buf;
				end
			end
		endcase
	end

   /********** バスインタフェ�`スの彜�B崙囮 **********/ 
   always @(posedge clk or `RESET_EDGE reset) begin
		if (reset == `RESET_ENABLE) begin
			/* 掲揖豚リセット */
			state		<= #1 `BUS_IF_STATE_IDLE;
			bus_req_	<= #1 `DISABLE_;
			bus_addr	<= #1 `WORD_ADDR_W'h0;
			bus_as_		<= #1 `DISABLE_;
			bus_rw		<= #1 `READ;
			bus_wr_data <= #1 `WORD_DATA_W'h0;
			rd_buf		<= #1 `WORD_DATA_W'h0;
		end else begin
			/* バスインタフェ�`スの彜�B */
			case (state)
				`BUS_IF_STATE_IDLE	 : begin // アイドル
					/* メモリアクセス */
					if ((flush == `DISABLE) && (as_ == `ENABLE_)) begin 
						/* アクセス枠の�x�k */
						if (s_index != `BUS_SLAVE_1) begin // バスへアクセス
							state		<= #1 `BUS_IF_STATE_REQ;
							bus_req_	<= #1 `ENABLE_;
							bus_addr	<= #1 addr;
							bus_rw		<= #1 rw;
							bus_wr_data <= #1 wr_data;
						end
					end
				end
				`BUS_IF_STATE_REQ	 : begin // バスリクエスト
					/* バスグラント棋ち */
					if (bus_grnt_ == `ENABLE_) begin // バス�惓@誼
						state		<= #1 `BUS_IF_STATE_ACCESS;
						bus_as_		<= #1 `ENABLE_;
					end
				end
				`BUS_IF_STATE_ACCESS : begin // バスアクセス
					/* アドレスストロ�`ブのネゲ�`ト */
					bus_as_		<= #1 `DISABLE_;
					/* レディ棋ち */
					if (bus_rdy_ == `ENABLE_) begin // レディ欺彭
						bus_req_	<= #1 `DISABLE_;
						bus_addr	<= #1 `WORD_ADDR_W'h0;
						bus_rw		<= #1 `READ;
						bus_wr_data <= #1 `WORD_DATA_W'h0;
						/* �iみ竃しデ�`タの隠贋 */
						if (bus_rw == `READ) begin // �iみ竃しアクセス
							rd_buf		<= #1 bus_rd_data;
						end
						/* スト�`ル�k伏のチェック */
						if (stall == `ENABLE) begin // スト�`ル�k伏
							state		<= #1 `BUS_IF_STATE_STALL;
						end else begin				// スト�`ル隆�k伏
							state		<= #1 `BUS_IF_STATE_IDLE;
						end
					end
				end
				`BUS_IF_STATE_STALL	 : begin // スト�`ル
					/* スト�`ル�k伏のチェック */
					if (stall == `DISABLE) begin // スト�`ル盾茅
						state		<= #1 `BUS_IF_STATE_IDLE;
					end
				end
			endcase
		end
	end

endmodule
