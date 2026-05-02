import csv
import re
import xml.etree.ElementTree as ET
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
REPO_DIR = BASE_DIR.parents[1]

NATIONAL_WASTE_FILE = BASE_DIR / "一般廢棄物清理情況資料.csv"
TAIPEI_WASTE_FILE = BASE_DIR / "廢棄物.csv"
POPULATION_FILE = BASE_DIR / "population.xml"
OUTPUT_FILE = REPO_DIR / "db-sample-data" / "dashboard-waste.sql"

DAYS_PER_YEAR = 365
GRAMS_PER_METRIC_TON = 1_000_000

METRIC_COLUMNS = [
    "garbagegenerated",
    "garbageclearance",
    "garbagerecycled",
    "foodwastesrecycled",
]

GROUP_LABELS = {
    "Taipei": "Taipei",
    "NewTaipei": "NewTaipei",
    "Other": "Other",
}


def clean_name(value):
    return (value or "").replace("\u3000", "").strip()


def parse_number(value):
    text = (value or "").replace(",", "").strip()
    if not text:
        return 0.0
    return float(text)


def parse_year(value):
    text = str(value).strip()
    match = re.search(r"\d+", text)
    if not match:
        raise ValueError(f"Cannot parse year from {value!r}")
    return int(match.group())


def group_city(city):
    city = clean_name(city)
    if city in ("臺北市", "Taipei City"):
        return "Taipei"
    if city in ("新北市", "New Taipei City"):
        return "NewTaipei"
    return "Other"


def load_national_waste_rows():
    with NATIONAL_WASTE_FILE.open(newline="", encoding="utf-8-sig") as csvfile:
        reader = csv.DictReader(csvfile)
        return [
            {
                "year": parse_year(row["year"]),
                "county": clean_name(row["county"]),
                **{column: parse_number(row[column]) for column in METRIC_COLUMNS},
            }
            for row in reader
        ]


def load_population_map(valid_counties):
    tree = ET.parse(POPULATION_FILE)
    root = tree.getroot()

    population_map = {}
    for item in root.findall("常住人口數及人口密度"):
        city = clean_name(item.findtext("按縣市別分_By_County_City"))
        pop_text = clean_name(
            item.findtext(
                "常住人口數_總計_人_Number_of_resident_population_Grand_total_person"
            )
        )

        if city not in valid_counties or not pop_text.isdigit():
            continue

        population_map[city] = int(pop_text)

    missing = sorted(valid_counties - population_map.keys())
    if missing:
        raise ValueError(f"population.xml missing county population: {missing}")

    return population_map


def group_population(population_map):
    grouped = {key: 0 for key in GROUP_LABELS}
    for city, population in population_map.items():
        grouped[group_city(city)] += population
    return grouped


def metric_tons_to_grams_per_person_day(metric_tons, population):
    return metric_tons * GRAMS_PER_METRIC_TON / population / DAYS_PER_YEAR


def build_grouped_rows(waste_rows, population_by_group):
    grouped = {}

    for row in waste_rows:
        year = row["year"]
        group = group_city(row["county"])
        grouped.setdefault((year, group), {column: 0.0 for column in METRIC_COLUMNS})

        for column in METRIC_COLUMNS:
            grouped[(year, group)][column] += row[column]

    output_rows = []
    for (year, group), values in sorted(grouped.items()):
        population = population_by_group[group]
        output_rows.append(
            {
                "year": year,
                "county": GROUP_LABELS[group],
                **{
                    column: metric_tons_to_grams_per_person_day(value, population)
                    for column, value in values.items()
                },
            }
        )

    return output_rows


def write_dashboard_sql(rows):
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT_FILE.open("w", encoding="utf-8", newline="\n") as outfile:
        outfile.write(
            """--
-- Waste source data
-- Values are grams per person per day.
--

DROP TABLE IF EXISTS public.waste_statistics;

CREATE TABLE public.waste_statistics (
    year INTEGER,
    county VARCHAR(50),
    garbagegenerated double precision,
    garbageclearance double precision,
    garbagerecycled double precision,
    foodwastesrecycled double precision
);

COPY public.waste_statistics (
    year,
    county,
    garbagegenerated,
    garbageclearance,
    garbagerecycled,
    foodwastesrecycled
) FROM stdin WITH (FORMAT csv);
"""
        )

        for row in rows:
            outfile.write(
                ",".join(
                    [
                        str(row["year"]),
                        row["county"],
                        f'{row["garbagegenerated"]:.6f}',
                        f'{row["garbageclearance"]:.6f}',
                        f'{row["garbagerecycled"]:.6f}',
                        f'{row["foodwastesrecycled"]:.6f}',
                    ]
                )
                + "\n"
            )

        outfile.write("\\.\n")


def print_taipei_source_note(waste_rows):
    if not TAIPEI_WASTE_FILE.exists():
        return

    national_by_year = {
        row["year"]: row for row in waste_rows if row["county"] == "臺北市"
    }

    with TAIPEI_WASTE_FILE.open(newline="", encoding="utf-8-sig") as csvfile:
        reader = csv.DictReader(csvfile)
        taipei_rows = {parse_year(row["統計期"]): row for row in reader}

    overlap = sorted(set(national_by_year) & set(taipei_rows))
    if not overlap:
        return

    latest = overlap[-1]
    city_row = taipei_rows[latest]
    national_row = national_by_year[latest]
    city_generated = parse_number(city_row["一般廢棄物產生量[公噸]"])

    if round(city_generated) != round(national_row["garbagegenerated"]):
        print(
            "提醒：廢棄物.csv 是臺北市單市資料，且與全國縣市檔最新重疊年度"
            f" {latest} 年數字不同；雙北比較目前使用全國縣市檔以保持口徑一致。"
        )


def main():
    waste_rows = load_national_waste_rows()
    valid_counties = {row["county"] for row in waste_rows}
    population_map = load_population_map(valid_counties)
    population_by_group = group_population(population_map)
    rows = build_grouped_rows(waste_rows, population_by_group)
    write_dashboard_sql(rows)
    print_taipei_source_note(waste_rows)
    print(f"完成：已輸出 {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
