/*
 -- ============================================================================
 -- FILE NAME	: cpu.v
 -- DESCRIPTION : CPUトップモジュ�`ル
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
`include "isa.h"
`include "cpu.h"
`include "bus.h"
`include "spm.h"

/********** モジュ�`ル **********/
module cpu (
	/********** クロック & リセット **********/
	input  wire					  clk,			   // クロック
	input  wire					  clk_,			   // 郡��クロック
	input  wire					  reset,		   // 掲揖豚リセット
	/********** バスインタフェ�`ス **********/
	// IF Stage
	input  wire [`WordDataBus]	  if_bus_rd_data,  // �iみ竃しデ�`タ
	input  wire					  if_bus_rdy_,	   // レディ
	input  wire					  if_bus_grnt_,	   // バスグラント
	output wire					  if_bus_req_,	   // バスリクエスト
	output wire [`WordAddrBus]	  if_bus_addr,	   // アドレス
	output wire					  if_bus_as_,	   // アドレスストロ�`ブ
	output wire					  if_bus_rw,	   // �iみ����き
	output wire [`WordDataBus]	  if_bus_wr_data,  // ��き�zみデ�`タ
	// MEM Stage
	input  wire [`WordDataBus]	  mem_bus_rd_data, // �iみ竃しデ�`タ
	input  wire					  mem_bus_rdy_,	   // レディ
	input  wire					  mem_bus_grnt_,   // バスグラント
	output wire					  mem_bus_req_,	   // バスリクエスト
	output wire [`WordAddrBus]	  mem_bus_addr,	   // アドレス
	output wire					  mem_bus_as_,	   // アドレスストロ�`ブ
	output wire					  mem_bus_rw,	   // �iみ����き
	output wire [`WordDataBus]	  mem_bus_wr_data, // ��き�zみデ�`タ
	/********** 護り�zみ **********/
	input  wire [`CPU_IRQ_CH-1:0] cpu_irq		   // 護り�zみ勣箔
);

	/********** パイプラインレジスタ **********/
	// IF/ID
	wire [`WordAddrBus]			 if_pc;			 // プログラムカウンタ
	wire [`WordDataBus]			 if_insn;		 // 凋綜
	wire						 if_en;			 // パイプラインデ�`タの嗤��
	// ID/EXパイプラインレジスタ
	wire [`WordAddrBus]			 id_pc;			 // プログラムカウンタ
	wire						 id_en;			 // パイプラインデ�`タの嗤��
	wire [`AluOpBus]			 id_alu_op;		 // ALUオペレ�`ション
	wire [`WordDataBus]			 id_alu_in_0;	 // ALU秘薦 0
	wire [`WordDataBus]			 id_alu_in_1;	 // ALU秘薦 1
	wire						 id_br_flag;	 // 蛍瓷フラグ
	wire [`MemOpBus]			 id_mem_op;		 // メモリオペレ�`ション
	wire [`WordDataBus]			 id_mem_wr_data; // メモリ��き�zみデ�`タ
	wire [`CtrlOpBus]			 id_ctrl_op;	 // 崙囮オペレ�`ション
	wire [`RegAddrBus]			 id_dst_addr;	 // GPR��き�zみアドレス
	wire						 id_gpr_we_;	 // GPR��き�zみ嗤��
	wire [`IsaExpBus]			 id_exp_code;	 // 箭翌コ�`ド
	// EX/MEMパイプラインレジスタ
	wire [`WordAddrBus]			 ex_pc;			 // プログラムカウンタ
	wire						 ex_en;			 // パイプラインデ�`タの嗤��
	wire						 ex_br_flag;	 // 蛍瓷フラグ
	wire [`MemOpBus]			 ex_mem_op;		 // メモリオペレ�`ション
	wire [`WordDataBus]			 ex_mem_wr_data; // メモリ��き�zみデ�`タ
	wire [`CtrlOpBus]			 ex_ctrl_op;	 // 崙囮レジスタオペレ�`ション
	wire [`RegAddrBus]			 ex_dst_addr;	 // ��喘レジスタ��き�zみアドレス
	wire						 ex_gpr_we_;	 // ��喘レジスタ��き�zみ嗤��
	wire [`IsaExpBus]			 ex_exp_code;	 // 箭翌コ�`ド
	wire [`WordDataBus]			 ex_out;		 // �I尖�Y惚
	// MEM/WBパイプラインレジスタ
	wire [`WordAddrBus]			 mem_pc;		 // プログランカウンタ
	wire						 mem_en;		 // パイプラインデ�`タの嗤��
	wire						 mem_br_flag;	 // 蛍瓷フラグ
	wire [`CtrlOpBus]			 mem_ctrl_op;	 // 崙囮レジスタオペレ�`ション
	wire [`RegAddrBus]			 mem_dst_addr;	 // ��喘レジスタ��き�zみアドレス
	wire						 mem_gpr_we_;	 // ��喘レジスタ��き�zみ嗤��
	wire [`IsaExpBus]			 mem_exp_code;	 // 箭翌コ�`ド
	wire [`WordDataBus]			 mem_out;		 // �I尖�Y惚
	/********** パイプライン崙囮佚催 **********/
	// スト�`ル佚催
	wire						 if_stall;		 // IFステ�`ジ
	wire						 id_stall;		 // IDステ�`
	wire						 ex_stall;		 // EXステ�`ジ
	wire						 mem_stall;		 // MEMステ�`ジ
	// フラッシュ佚催
	wire						 if_flush;		 // IFステ�`ジ
	wire						 id_flush;		 // IDステ�`ジ
	wire						 ex_flush;		 // EXステ�`ジ
	wire						 mem_flush;		 // MEMステ�`ジ
	// ビジ�`佚催
	wire						 if_busy;		 // IFステ�`ジ
	wire						 mem_busy;		 // MEMステ�`ジ
	// その麿の崙囮佚催
	wire [`WordAddrBus]			 new_pc;		 // 仟しいPC
	wire [`WordAddrBus]			 br_addr;		 // 蛍瓷アドレス
	wire						 br_taken;		 // 蛍瓷の撹羨
	wire						 ld_hazard;		 // ロ�`ドハザ�`ド
	/********** ��喘レジスタ佚催 **********/
	wire [`WordDataBus]			 gpr_rd_data_0;	 // �iみ竃しデ�`タ 0
	wire [`WordDataBus]			 gpr_rd_data_1;	 // �iみ竃しデ�`タ 1
	wire [`RegAddrBus]			 gpr_rd_addr_0;	 // �iみ竃しアドレス 0
	wire [`RegAddrBus]			 gpr_rd_addr_1;	 // �iみ竃しアドレス 1
	/********** 崙囮レジスタ佚催 **********/
	wire [`CpuExeModeBus]		 exe_mode;		 // �g佩モ�`ド
	wire [`WordDataBus]			 creg_rd_data;	 // �iみ竃しデ�`タ
	wire [`RegAddrBus]			 creg_rd_addr;	 // �iみ竃しアドレス
	/********** Interrupt Request **********/
	wire						 int_detect;	  // 護り�zみ�奮�
	/********** スクラッチパッドメモリ佚催 **********/
	// IFステ�`ジ
	wire [`WordDataBus]			 if_spm_rd_data;  // �iみ竃しデ�`タ
	wire [`WordAddrBus]			 if_spm_addr;	  // アドレス
	wire						 if_spm_as_;	  // アドレスストロ�`ブ
	wire						 if_spm_rw;		  // �iみ����き
	wire [`WordDataBus]			 if_spm_wr_data;  // ��き�zみデ�`タ
	// MEMステ�`ジ
	wire [`WordDataBus]			 mem_spm_rd_data; // �iみ竃しデ�`タ
	wire [`WordAddrBus]			 mem_spm_addr;	  // アドレス
	wire						 mem_spm_as_;	  // アドレスストロ�`ブ
	wire						 mem_spm_rw;	  // �iみ����き
	wire [`WordDataBus]			 mem_spm_wr_data; // ��き�zみデ�`タ
	/********** フォワ�`ディング佚催 **********/
	wire [`WordDataBus]			 ex_fwd_data;	  // EXステ�`ジ
	wire [`WordDataBus]			 mem_fwd_data;	  // MEMステ�`ジ

	/********** IFステ�`ジ **********/
	if_stage if_stage (
		/********** クロック & リセット **********/
		.clk			(clk),				// クロック
		.reset			(reset),			// 掲揖豚リセット
		/********** SPMインタフェ�`ス **********/
		.spm_rd_data	(if_spm_rd_data),	// �iみ竃しデ�`タ
		.spm_addr		(if_spm_addr),		// アドレス
		.spm_as_		(if_spm_as_),		// アドレスストロ�`ブ
		.spm_rw			(if_spm_rw),		// �iみ����き
		.spm_wr_data	(if_spm_wr_data),	// ��き�zみデ�`タ
		/********** バスインタフェ�`ス **********/
		.bus_rd_data	(if_bus_rd_data),	// �iみ竃しデ�`タ
		.bus_rdy_		(if_bus_rdy_),		// レディ
		.bus_grnt_		(if_bus_grnt_),		// バスグラント
		.bus_req_		(if_bus_req_),		// バスリクエスト
		.bus_addr		(if_bus_addr),		// アドレス
		.bus_as_		(if_bus_as_),		// アドレスストロ�`ブ
		.bus_rw			(if_bus_rw),		// �iみ����き
		.bus_wr_data	(if_bus_wr_data),	// ��き�zみデ�`タ
		/********** パイプライン崙囮佚催 **********/
		.stall			(if_stall),			// スト�`ル
		.flush			(if_flush),			// フラッシュ
		.new_pc			(new_pc),			// 仟しいPC
		.br_taken		(br_taken),			// 蛍瓷の撹羨
		.br_addr		(br_addr),			// 蛍瓷枠アドレス
		.busy			(if_busy),			// ビジ�`佚催
		/********** IF/IDパイプラインレジスタ **********/
		.if_pc			(if_pc),			// プログラムカウンタ
		.if_insn		(if_insn),			// 凋綜
		.if_en			(if_en)				// パイプラインデ�`タの嗤��
	);

	/********** IDステ�`ジ **********/
	id_stage id_stage (
		/********** クロック & リセット **********/
		.clk			(clk),				// クロック
		.reset			(reset),			// 掲揖豚リセット
		/********** GPRインタフェ�`ス **********/
		.gpr_rd_data_0	(gpr_rd_data_0),	// �iみ竃しデ�`タ 0
		.gpr_rd_data_1	(gpr_rd_data_1),	// �iみ竃しデ�`タ 1
		.gpr_rd_addr_0	(gpr_rd_addr_0),	// �iみ竃しアドレス 0
		.gpr_rd_addr_1	(gpr_rd_addr_1),	// �iみ竃しアドレス 1
		/********** フォワ�`ディング **********/
		// EXステ�`ジからのフォワ�`ディング
		.ex_en			(ex_en),			// パイプラインデ�`タの嗤��
		.ex_fwd_data	(ex_fwd_data),		// フォワ�`ディングデ�`タ
		.ex_dst_addr	(ex_dst_addr),		// ��き�zみアドレス
		.ex_gpr_we_		(ex_gpr_we_),		// ��き�zみ嗤��
		// MEMステ�`ジからのフォワ�`ディング
		.mem_fwd_data	(mem_fwd_data),		// フォワ�`ディングデ�`タ
		/********** 崙囮レジスタインタフェ�`ス **********/
		.exe_mode		(exe_mode),			// �g佩モ�`ド
		.creg_rd_data	(creg_rd_data),		// �iみ竃しデ�`タ
		.creg_rd_addr	(creg_rd_addr),		// �iみ竃しアドレス
		/********** パイプライン崙囮佚催 **********/
	   .stall		   (id_stall),		   // スト�`ル
		.flush			(id_flush),			// フラッシュ
		.br_addr		(br_addr),			// 蛍瓷アドレス
		.br_taken		(br_taken),			// 蛍瓷の撹羨
		.ld_hazard		(ld_hazard),		// ロ�`ドハザ�`ド
		/********** IF/IDパイプラインレジスタ **********/
		.if_pc			(if_pc),			// プログラムカウンタ
		.if_insn		(if_insn),			// 凋綜
		.if_en			(if_en),			// パイプラインデ�`タの嗤��
		/********** ID/EXパイプラインレジスタ **********/
		.id_pc			(id_pc),			// プログラムカウンタ
		.id_en			(id_en),			// パイプラインデ�`タの嗤��
		.id_alu_op		(id_alu_op),		// ALUオペレ�`ション
		.id_alu_in_0	(id_alu_in_0),		// ALU秘薦 0
		.id_alu_in_1	(id_alu_in_1),		// ALU秘薦 1
		.id_br_flag		(id_br_flag),		// 蛍瓷フラグ
		.id_mem_op		(id_mem_op),		// メモリオペレ�`ション
		.id_mem_wr_data (id_mem_wr_data),	// メモリ��き�zみデ�`タ
		.id_ctrl_op		(id_ctrl_op),		// 崙囮オペレ�`ション
		.id_dst_addr	(id_dst_addr),		// GPR��き�zみアドレス
		.id_gpr_we_		(id_gpr_we_),		// GPR��き�zみ嗤��
		.id_exp_code	(id_exp_code)		// 箭翌コ�`ド
	);

	/********** EXステ�`ジ **********/
	ex_stage ex_stage (
		/********** クロック & リセット **********/
		.clk			(clk),				// クロック
		.reset			(reset),			// 掲揖豚リセット
		/********** パイプライン崙囮佚催 **********/
		.stall			(ex_stall),			// スト�`ル
		.flush			(ex_flush),			// フラッシュ
		.int_detect		(int_detect),		// 護り�zみ�奮�
		/********** フォワ�`ディング **********/
		.fwd_data		(ex_fwd_data),		// フォワ�`ディングデ�`タ
		/********** ID/EXパイプラインレジスタ **********/
		.id_pc			(id_pc),			// プログラムカウンタ
		.id_en			(id_en),			// パイプラインデ�`タの嗤��
		.id_alu_op		(id_alu_op),		// ALUオペレ�`ション
		.id_alu_in_0	(id_alu_in_0),		// ALU秘薦 0
		.id_alu_in_1	(id_alu_in_1),		// ALU秘薦 1
		.id_br_flag		(id_br_flag),		// 蛍瓷フラグ
		.id_mem_op		(id_mem_op),		// メモリオペレ�`ション
		.id_mem_wr_data (id_mem_wr_data),	// メモリ��き�zみデ�`タ
		.id_ctrl_op		(id_ctrl_op),		// 崙囮レジスタオペレ�`ション
		.id_dst_addr	(id_dst_addr),		// ��喘レジスタ��き�zみアドレス
		.id_gpr_we_		(id_gpr_we_),		// ��喘レジスタ��き�zみ嗤��
		.id_exp_code	(id_exp_code),		// 箭翌コ�`ド
		/********** EX/MEMパイプラインレジスタ **********/
		.ex_pc			(ex_pc),			// プログラムカウンタ
		.ex_en			(ex_en),			// パイプラインデ�`タの嗤��
		.ex_br_flag		(ex_br_flag),		// 蛍瓷フラグ
		.ex_mem_op		(ex_mem_op),		// メモリオペレ�`ション
		.ex_mem_wr_data (ex_mem_wr_data),	// メモリ��き�zみデ�`タ
		.ex_ctrl_op		(ex_ctrl_op),		// 崙囮レジスタオペレ�`ション
		.ex_dst_addr	(ex_dst_addr),		// ��喘レジスタ��き�zみアドレス
		.ex_gpr_we_		(ex_gpr_we_),		// ��喘レジスタ��き�zみ嗤��
		.ex_exp_code	(ex_exp_code),		// 箭翌コ�`ド
		.ex_out			(ex_out)			// �I尖�Y惚
	);

	/********** MEMステ�`ジ **********/
	mem_stage mem_stage (
		/********** クロック & リセット **********/
		.clk			(clk),				// クロック
		.reset			(reset),			// 掲揖豚リセット
		/********** パイプライン崙囮佚催 **********/
		.stall			(mem_stall),		// スト�`ル
		.flush			(mem_flush),		// フラッシュ
		.busy			(mem_busy),			// ビジ�`佚催
		/********** フォワ�`ディング **********/
		.fwd_data		(mem_fwd_data),		// フォワ�`ディングデ�`タ
		/********** SPMインタフェ�`ス **********/
		.spm_rd_data	(mem_spm_rd_data),	// �iみ竃しデ�`タ
		.spm_addr		(mem_spm_addr),		// アドレス
		.spm_as_		(mem_spm_as_),		// アドレスストロ�`ブ
		.spm_rw			(mem_spm_rw),		// �iみ����き
		.spm_wr_data	(mem_spm_wr_data),	// ��き�zみデ�`タ
		/********** バスインタフェ�`ス **********/
		.bus_rd_data	(mem_bus_rd_data),	// �iみ竃しデ�`タ
		.bus_rdy_		(mem_bus_rdy_),		// レディ
		.bus_grnt_		(mem_bus_grnt_),	// バスグラント
		.bus_req_		(mem_bus_req_),		// バスリクエスト
		.bus_addr		(mem_bus_addr),		// アドレス
		.bus_as_		(mem_bus_as_),		// アドレスストロ�`ブ
		.bus_rw			(mem_bus_rw),		// �iみ����き
		.bus_wr_data	(mem_bus_wr_data),	// ��き�zみデ�`タ
		/********** EX/MEMパイプラインレジスタ **********/
		.ex_pc			(ex_pc),			// プログラムカウンタ
		.ex_en			(ex_en),			// パイプラインデ�`タの嗤��
		.ex_br_flag		(ex_br_flag),		// 蛍瓷フラグ
		.ex_mem_op		(ex_mem_op),		// メモリオペレ�`ション
		.ex_mem_wr_data (ex_mem_wr_data),	// メモリ��き�zみデ�`タ
		.ex_ctrl_op		(ex_ctrl_op),		// 崙囮レジスタオペレ�`ション
		.ex_dst_addr	(ex_dst_addr),		// ��喘レジスタ��き�zみアドレス
		.ex_gpr_we_		(ex_gpr_we_),		// ��喘レジスタ��き�zみ嗤��
		.ex_exp_code	(ex_exp_code),		// 箭翌コ�`ド
		.ex_out			(ex_out),			// �I尖�Y惚
		/********** MEM/WBパイプラインレジスタ **********/
		.mem_pc			(mem_pc),			// プログランカウンタ
		.mem_en			(mem_en),			// パイプラインデ�`タの嗤��
		.mem_br_flag	(mem_br_flag),		// 蛍瓷フラグ
		.mem_ctrl_op	(mem_ctrl_op),		// 崙囮レジスタオペレ�`ション
		.mem_dst_addr	(mem_dst_addr),		// ��喘レジスタ��き�zみアドレス
		.mem_gpr_we_	(mem_gpr_we_),		// ��喘レジスタ��き�zみ嗤��
		.mem_exp_code	(mem_exp_code),		// 箭翌コ�`ド
		.mem_out		(mem_out)			// �I尖�Y惚
	);

	/********** 崙囮ユニット **********/
	ctrl ctrl (
		/********** クロック & リセット **********/
		.clk			(clk),				// クロック
		.reset			(reset),			// 掲揖豚リセット
		/********** 崙囮レジスタインタフェ�`ス **********/
		.creg_rd_addr	(creg_rd_addr),		// �iみ竃しアドレス
		.creg_rd_data	(creg_rd_data),		// �iみ竃しデ�`タ
		.exe_mode		(exe_mode),			// �g佩モ�`ド
		/********** 護り�zみ **********/
		.irq			(cpu_irq),			// 護り�zみ勣箔
		.int_detect		(int_detect),		// 護り�zみ�奮�
		/********** ID/EXパイプラインレジスタ **********/
		.id_pc			(id_pc),			// プログラムカウンタ
		/********** MEM/WBパイプラインレジスタ **********/
		.mem_pc			(mem_pc),			// プログランカウンタ
		.mem_en			(mem_en),			// パイプラインデ�`タの嗤��
		.mem_br_flag	(mem_br_flag),		// 蛍瓷フラグ
		.mem_ctrl_op	(mem_ctrl_op),		// 崙囮レジスタオペレ�`ション
		.mem_dst_addr	(mem_dst_addr),		// ��喘レジスタ��き�zみアドレス
		.mem_exp_code	(mem_exp_code),		// 箭翌コ�`ド
		.mem_out		(mem_out),			// �I尖�Y惚
		/********** パイプライン崙囮佚催 **********/
		// パイプラインの彜�B
		.if_busy		(if_busy),			// IFステ�`ジビジ�`
		.ld_hazard		(ld_hazard),		// Loadハザ�`ド
		.mem_busy		(mem_busy),			// MEMステ�`ジビジ�`
		// スト�`ル佚催
		.if_stall		(if_stall),			// IFステ�`ジスト�`ル
		.id_stall		(id_stall),			// IDステ�`ジスト�`ル
		.ex_stall		(ex_stall),			// EXステ�`ジスト�`ル
		.mem_stall		(mem_stall),		// MEMステ�`ジスト�`ル
		// フラッシュ佚催
		.if_flush		(if_flush),			// IFステ�`ジフラッシュ
		.id_flush		(id_flush),			// IDステ�`ジフラッシュ
		.ex_flush		(ex_flush),			// EXステ�`ジフラッシュ
		.mem_flush		(mem_flush),		// MEMステ�`ジフラッシュ
		// 仟しいプログラムカウンタ
		.new_pc			(new_pc)			// 仟しいプログラムカウンタ
	);

	/********** ��喘レジスタ **********/
	gpr gpr (
		/********** クロック & リセット **********/
		.clk	   (clk),					// クロック
		.reset	   (reset),					// 掲揖豚リセット
		/********** �iみ竃しポ�`ト 0 **********/
		.rd_addr_0 (gpr_rd_addr_0),			// �iみ竃しアドレス
		.rd_data_0 (gpr_rd_data_0),			// �iみ竃しデ�`タ
		/********** �iみ竃しポ�`ト 1 **********/
		.rd_addr_1 (gpr_rd_addr_1),			// �iみ竃しアドレス
		.rd_data_1 (gpr_rd_data_1),			// �iみ竃しデ�`タ
		/********** ��き�zみポ�`ト **********/
		.we_	   (mem_gpr_we_),			// ��き�zみ嗤��
		.wr_addr   (mem_dst_addr),			// ��き�zみアドレス
		.wr_data   (mem_out)				// ��き�zみデ�`タ
	);

	/********** スクラッチパッドメモリ **********/
	spm spm (
		/********** クロック **********/
		.clk			 (clk_),					  // クロック
		/********** ポ�`トA : IFステ�`ジ **********/
		.if_spm_addr	 (if_spm_addr[`SpmAddrLoc]),  // アドレス
		.if_spm_as_		 (if_spm_as_),				  // アドレスストロ�`ブ
		.if_spm_rw		 (if_spm_rw),				  // �iみ����き
		.if_spm_wr_data	 (if_spm_wr_data),			  // ��き�zみデ�`タ
		.if_spm_rd_data	 (if_spm_rd_data),			  // �iみ竃しデ�`タ
		/********** ポ�`トB : MEMステ�`ジ **********/
		.mem_spm_addr	 (mem_spm_addr[`SpmAddrLoc]), // アドレス
		.mem_spm_as_	 (mem_spm_as_),				  // アドレスストロ�`ブ
		.mem_spm_rw		 (mem_spm_rw),				  // �iみ����き
		.mem_spm_wr_data (mem_spm_wr_data),			  // ��き�zみデ�`タ
		.mem_spm_rd_data (mem_spm_rd_data)			  // �iみ竃しデ�`タ
	);

endmodule
