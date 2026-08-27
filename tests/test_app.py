import pytest
from app.main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestHealthEndpoint:
    def test_health_returns_200(self, client):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_json(self, client):
        response = client.get("/health")
        data = response.get_json()
        assert data["status"] == "healthy"
        assert "service" in data

    def test_health_content_type(self, client):
        response = client.get("/health")
        assert response.content_type == "application/json"


class TestStatusEndpoint:
    def test_status_returns_200(self, client):
        response = client.get("/status")
        assert response.status_code == 200

    def test_status_contains_uptime(self, client):
        response = client.get("/status")
        data = response.get_json()
        assert "uptime_seconds" in data
        assert isinstance(data["uptime_seconds"], int)

    def test_status_contains_environment(self, client):
        response = client.get("/status")
        data = response.get_json()
        assert "environment" in data
        assert data["status"] == "running"


class TestInfoEndpoint:
    def test_info_returns_200(self, client):
        response = client.get("/info")
        assert response.status_code == 200

    def test_info_contains_required_fields(self, client):
        response = client.get("/info")
        data = response.get_json()
        assert "app" in data
        assert "version" in data
        assert "python_version" in data
        assert "author" in data

    def test_info_author_is_correct(self, client):
        response = client.get("/info")
        data = response.get_json()
        assert data["author"] == "ToubaSlam"
