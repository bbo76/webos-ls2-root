# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

People testing LS2 behavior on an LG webOS TV from a Mac, using the TV browser and Magic Remote.

## Product Purpose

The bootstrap page registers a temporary LS2 manifest on the TV and displays the independent root verification result reported by the Mac. Success means the manifest is registered and the Mac confirms root execution.

## Positioning

This is an experimental research and diagnostic tool, not a consumer product.

## Operating Context

The page runs in tinybrowser on the TV with Developer Mode enabled. Users navigate it at viewing distance with a Magic Remote or directional keys while the Mac runs the local verification flow.

## Capabilities and Constraints

- The page checks PalmServiceBridge and its local session before enabling the bootstrap slider.
- Moving the range control to 100% starts manifest registration.
- The page reports `running`, `registered`, and `error` states to the local server and polls for `verified` results.
- Preserve the existing LS2 calls, HTTP endpoints, session token handling, and state values.
- Compatibility is confirmed only on the tested LG OLED55C35LA (C3) and firmware 43.21.96.

## Evidence on Hand

The project contains technical notes and scripts documenting the tested LS2 behavior and verification process. It has no provided logo or brand assets.

## Product Principles

- Make the next action and current state readable from across a room.
- Keep the TV workflow operable with directional input.
- Show only verified results; make experimental and unverified behavior clear.
- Preserve a clear distinction between manifest registration and root verification.
