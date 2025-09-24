#!/usr/bin/env python3
import json
import os
import pybadges  # make sure you pip-install this in your workflow

# Paths
data_file = os.path.join(os.getcwd(), 'milestones/milestones.json')
out_dir   = os.path.join(os.getcwd(), 'badges')
os.makedirs(out_dir, exist_ok=True)

# Load milestones
with open(data_file) as f:
    milestones = json.load(f)['milestones']

for m in milestones:
    color = 'brightgreen' if m['status'] == 'completed' else 'orange'
    svg   = pybadges.badge(
        left        = m['name'],
        right       = m['status'],
        right_color = color,
        style       = 'flat'
    )
    path = os.path.join(out_dir, f"{m['id']}.svg")
    with open(path, 'w') as out:
        out.write(svg)
    print(f'• Generated badge: {m["id"]}.svg')
