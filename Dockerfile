# Langflow + Playwright Python (Chromium runs in a separate Browserless service)
FROM langflowai/langflow:1.12.1
USER root
RUN microdnf install -y libatomic && microdnf clean all
RUN uv pip install --python /app/.venv/bin/python 'playwright==1.58.0' && /app/.venv/bin/python -c "import playwright.sync_api; print('Playwright ready')"
USER user
