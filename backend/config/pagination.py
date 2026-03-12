from rest_framework.pagination import PageNumberPagination
from rest_framework.utils.urls import replace_query_param, remove_query_param


class OptInPageNumberPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 200

    def get_page_size(self, request):
        if (
            "page" not in request.query_params
            and "page_size" not in request.query_params
            and request.query_params.get("paginated") != "1"
        ):
            return None
        return super().get_page_size(request)

    def get_next_link(self):
        if not self.page.has_next():
            return None
        url = self.request.get_full_path()
        page_number = self.page.next_page_number()
        return replace_query_param(url, self.page_query_param, page_number)

    def get_previous_link(self):
        if not self.page.has_previous():
            return None
        url = self.request.get_full_path()
        page_number = self.page.previous_page_number()
        if page_number == 1:
            return remove_query_param(url, self.page_query_param)
        return replace_query_param(url, self.page_query_param, page_number)


class TaskListPagination(OptInPageNumberPagination):
    page_size = 40


class ProjectDashboardPagination(OptInPageNumberPagination):
    page_size = 20
    max_page_size = 100
