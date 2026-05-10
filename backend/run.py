from app import create_app

app = create_app()

print("=== Rotas registradas ===")
for rule in app.url_map.iter_rules():
    print(f"  {list(rule.methods)} {rule}")
print("========================")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, use_reloader=False)
