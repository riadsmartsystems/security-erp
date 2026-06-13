#!/usr/bin/env python3
import argparse
import asyncio
import json
import os

import nats


def parse_csv(value: str) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


def build_payload(args: argparse.Namespace) -> dict:
    payload = {
        "channels": args.channels,
        "message": args.message,
    }

    telegram_ids = parse_csv(args.telegram_ids)
    if telegram_ids:
        payload["telegram_chat_ids"] = telegram_ids

    viber_ids = parse_csv(args.viber_ids)
    if viber_ids:
        payload["viber_user_ids"] = viber_ids

    if args.subject == "fsm.sla.breached":
        payload = {
            "ticket_number": args.ticket_number,
            "type": args.sla_type,
            "priority": args.priority,
        }

    return payload


async def publish(args: argparse.Namespace):
    payload = build_payload(args)
    nats_url = args.nats_url or os.getenv("NATS_URL", "nats://nats:nats_secret@nats:4222")

    print(f"Connecting to NATS: {nats_url}")
    nc = await nats.connect(nats_url)
    try:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        await nc.publish(args.subject, body)
        await nc.flush()
        print(f"Published to subject: {args.subject}")
        print(f"Payload: {json.dumps(payload, ensure_ascii=False)}")
    finally:
        await nc.close()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Publish test notification events to NATS",
    )
    parser.add_argument(
        "--subject",
        default="notifications.send",
        choices=["notifications.send", "fsm.sla.breached"],
        help="NATS subject to publish",
    )
    parser.add_argument(
        "--nats-url",
        default="",
        help="NATS URL (fallback: NATS_URL env or default internal URL)",
    )

    parser.add_argument(
        "--message",
        default="Тестове повідомлення з NATS",
        help="Notification message text for notifications.send",
    )
    parser.add_argument(
        "--channels",
        nargs="+",
        default=["telegram"],
        choices=["telegram", "viber"],
        help="Channels for notifications.send",
    )
    parser.add_argument(
        "--telegram-ids",
        default="",
        help="Comma-separated Telegram chat IDs",
    )
    parser.add_argument(
        "--viber-ids",
        default="",
        help="Comma-separated Viber user IDs",
    )

    parser.add_argument(
        "--ticket-number",
        default="TCK-TEST-001",
        help="Ticket number for fsm.sla.breached",
    )
    parser.add_argument(
        "--sla-type",
        default="response",
        choices=["response", "arrival", "resolution"],
        help="SLA timer type for fsm.sla.breached",
    )
    parser.add_argument(
        "--priority",
        default="high",
        choices=["low", "medium", "high", "critical"],
        help="Priority for fsm.sla.breached",
    )
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    asyncio.run(publish(args))


if __name__ == "__main__":
    main()
