#!/usr/bin/env python3
"""
Bhasha AI - Chinese Noisy Speech Recognition & Translation System
Powered by Whisper Large-v3 & Opus-MT NMT
"""

import os
import sys
import argparse
import json
import re
import torch
from transformers import (
    AutoModelForSpeechSeq2Seq,
    AutoProcessor,
    pipeline,
    AutoTokenizer,
    AutoModelForSeq2SeqLM
)

def clean_repetition(text):
    if not text:
        return ""
    tokens = text.split()
    if len(tokens) > 10:
        cleaned = []
        repeat_count = 0
        last_tok = None
        for tok in tokens:
            if tok == last_tok:
                repeat_count += 1
            else:
                repeat_count = 0
                last_tok = tok
            if repeat_count < 3:
                cleaned.append(tok)
        return " ".join(cleaned)
    return text

class SpeechTranslator:
    def __init__(self, device=None):
        self.device = device or ("cuda:0" if torch.cuda.is_available() else "cpu")
        self.torch_dtype = torch.float16 if torch.cuda.is_available() else torch.float32
        print(f"Loading models on {self.device}...")

        whisper_id = "openai/whisper-large-v3"
        self.whisper_model = AutoModelForSpeechSeq2Seq.from_pretrained(
            whisper_id,
            torch_dtype=self.torch_dtype,
            low_cpu_mem_usage=True,
            use_safetensors=True
        ).to(self.device)
        self.whisper_processor = AutoProcessor.from_pretrained(whisper_id)

        self.asr_pipe = pipeline(
            "automatic-speech-recognition",
            model=self.whisper_model,
            tokenizer=self.whisper_processor.tokenizer,
            feature_extractor=self.whisper_processor.feature_extractor,
            torch_dtype=self.torch_dtype,
            device=self.device,
            return_timestamps=True
        )

        nmt_id = "Helsinki-NLP/opus-mt-zh-en"
        self.nmt_tokenizer = AutoTokenizer.from_pretrained(nmt_id)
        self.nmt_model = AutoModelForSeq2SeqLM.from_pretrained(nmt_id).to(self.device)

        domain_prompt = "这是一段工地施工与车辆调度对讲机通话录音，包含装载机、挖掘机、罐车、平板车、自卸车、班组、水桶、爆破、放炮、打眼、拉萨、挡墙、变压器等对话。"
        self.prompt_ids = self.whisper_processor.get_prompt_ids(domain_prompt, return_tensors="pt").to(self.device)
        print("Models loaded successfully!")

    def translate_zh_to_en(self, text):
        if not text or not text.strip():
            return ""
        text = re.sub(r'([说请问啊嗯吧呀呢点赞订阅转发])\1{3,}', r'\1', text)
        sentences = re.split(r'([。！？\n])', text)
        chunks = []
        cur = ""
        for part in sentences:
            cur += part
            if len(cur) > 70 or part in ['。', '！', '？', '\n']:
                if cur.strip():
                    chunks.append(cur.strip())
                cur = ""
        if cur.strip():
            chunks.append(cur.strip())
        
        translated_parts = []
        for chunk in chunks:
            inputs = self.nmt_tokenizer(chunk, return_tensors="pt", padding=True, truncation=True, max_length=512).to(self.device)
            outputs = self.nmt_model.generate(**inputs, max_length=512, num_beams=4)
            trans = self.nmt_tokenizer.decode(outputs[0], skip_special_tokens=True)
            if trans.strip():
                translated_parts.append(trans.strip())
        return " ".join(translated_parts)

    def process_file(self, audio_path):
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found: {audio_path}")

        # Chinese ASR
        res_zh = self.asr_pipe(
            audio_path,
            generate_kwargs={
                "task": "transcribe",
                "language": "chinese",
                "prompt_ids": self.prompt_ids,
                "repetition_penalty": 1.15,
                "no_repeat_ngram_size": 4
            }
        )
        zh_text = res_zh.get("text", "").strip()
        zh_text = re.sub(r'([说请问啊嗯吧呀呢点赞订阅转发])\1{3,}', '', zh_text)
        chunks = res_zh.get("chunks", [])

        # Direct Whisper Translation
        res_en = self.asr_pipe(
            audio_path,
            generate_kwargs={
                "task": "translate",
                "language": "chinese",
                "prompt_ids": self.prompt_ids,
                "repetition_penalty": 1.15,
                "no_repeat_ngram_size": 4
            }
        )
        whisper_en = clean_repetition(res_en.get("text", "").strip())

        # Neural NMT Translation
        opus_en = self.translate_zh_to_en(zh_text)

        return {
            "audio_file": os.path.basename(audio_path),
            "chinese_transcript": zh_text,
            "whisper_direct_translation": whisper_en,
            "opus_mt_translation": opus_en,
            "timestamps": [
                {"start": c.get("timestamp", [0, 0])[0], "end": c.get("timestamp", [0, 0])[1], "text": c.get("text", "")}
                for c in chunks if c.get("timestamp")
            ]
        }

def main():
    parser = argparse.ArgumentParser(description="Transcribe and Translate Chinese audio files")
    parser.add_argument("--audio", type=str, help="Path to a single audio file (.mp3, .wav, etc.)")
    parser.add_argument("--dir", type=str, help="Path to directory containing audio files")
    parser.add_argument("--output", type=str, default="output.json", help="Path to save output JSON")
    args = parser.parse_args()

    if not args.audio and not args.dir:
        parser.print_help()
        sys.exit(1)

    translator = SpeechTranslator()

    if args.audio:
        print(f"\nProcessing single file: {args.audio}")
        res = translator.process_file(args.audio)
        print("\n" + "="*50)
        print("🇨🇳 Chinese Transcript:")
        print(res["chinese_transcript"])
        print("\n🌐 Direct Whisper Translation (EN):")
        print(res["whisper_direct_translation"])
        print("\n📖 Opus-MT Translation (EN):")
        print(res["opus_mt_translation"])
        print("="*50)
    elif args.dir:
        files = [os.path.join(args.dir, f) for f in os.listdir(args.dir) if f.lower().endswith(('.mp3', '.wav', '.flac', '.m4a', '.ogg'))]
        print(f"\nProcessing {len(files)} files in {args.dir}...")
        results = []
        for i, f in enumerate(files, 1):
            print(f"[{i}/{len(files)}] Processing {os.path.basename(f)}...")
            res = translator.process_file(f)
            results.append(res)
        with open(args.output, "w", encoding="utf-8") as out:
            json.dump(results, out, ensure_ascii=False, indent=2)
        print(f"Results saved to {args.output}")

if __name__ == "__main__":
    main()
