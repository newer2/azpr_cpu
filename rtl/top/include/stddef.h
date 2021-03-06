/*
 -- ============================================================================
 -- FILE NAME	: stddef.h
 -- DESCRIPTION : 常用宏定义 
 -- ----------------------------------------------------------------------------
 -- Revision  Date		  Coding_by	 Comment
 -- 1.0.0	  2011/04/01  suito		 新規作成
 -- 1.0.1	  2014/07/27  zhangly 
 -- ============================================================================
*/

`ifndef __STDDEF_HEADER__				 // 
	`define __STDDEF_HEADER__

// -----------------------------------------------------------------------------
// 信号值
// -----------------------------------------------------------------------------
	/********** 信号值 *********/
	`define HIGH				1'b1	 // 高电平信号
	`define LOW					1'b0	 // 低电平信号
	/********** 有効／無効 *********/
	// 正逻辑
	`define DISABLE				1'b0	 // 无效
	`define ENABLE				1'b1	 // 有效
	// 负逻辑
	`define DISABLE_			1'b1	 // 无效
	`define ENABLE_				1'b0	 // 有效
	/********** 读/写  *********/
	`define READ				1'b1	 // 读取信号
	`define WRITE				1'b0	 // 写入信号

// -----------------------------------------------------------------------------
//数据总线
// -----------------------------------------------------------------------------
	/********** 最低位 *********/
	`define LSB					0		 // 最低位
	/********** 字节 (8 bit) *********/
	`define BYTE_DATA_W			8		 // 数据宽度（字节）
	`define BYTE_MSB			7		 // 最高位（字节）
	`define ByteDataBus			7:0		 // 数据总线（字节）
	/********** 字 (32 bit) *********/
	`define WORD_DATA_W			32		 // 数据宽度（字）
	`define WORD_MSB			31		 // 最高位（字）
	`define WordDataBus			31:0	 // 数据总线（字）

// -----------------------------------------------------------------------------
// 地址总线：字编址与字节位移，本cpu是32位，每四字节分配一地址，在cpu内部高30位以字编址，低2位用作字节位移使用
// -----------------------------------------------------------------------------
	/********** 数据地址（字为单位） *********/
	`define WORD_ADDR_W			30		 // 数据宽度（字）
	`define WORD_ADDR_MSB		29		 // 最高位
	`define WordAddrBus			29:0	 // 数据总线
	/********** 字七位移 *********/
	`define BYTE_OFFSET_W		2		 // 位移位宽
	`define ByteOffsetBus		1:0		 // 位移总线
	/********** 字地址索引 *********/
	`define WordAddrLoc			31:2	 // 字地址位置
	`define ByteOffsetLoc		1:0		 // 字节位移位置
	/********** 字节的偏移值 *********/
	`define BYTE_OFFSET_WORD	2'b00	 // 字边界

`endif
