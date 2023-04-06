import argparse
import logging
import yaml
import json
import datetime
import os

from triage.experiments import MultiCoreExperiment
from triage import create_engine

from sqlalchemy.event import listens_for
from sqlalchemy.pool import Pool
from sqlalchemy.engine.url import URL


PROJECT_PATH = '/data/analysis/triage_runs'

def run(config_filename, verbose, replace, predictions, validate_only):
    # configure logging
    # add logging to a file (it will also go to stdout via triage logging config)
    log_filename = os.path.join('/data/analysis/triage_runs/', 'triage.log')
    logger = logging.getLogger('')
    hdlr = logging.FileHandler(log_filename)
    #hdlr.setLevel(15)   # verbose level
    hdlr.setLevel(logging.SPAM)
    hdlr.setFormatter(logging.Formatter('%(name)-30s  %(asctime)s %(levelname)10s %(process)6d  %(filename)-24s  %(lineno)4d: %(message)s', '%d/%m/%Y %I:%M:%S %p'))
    logger.addHandler(hdlr)


    # load main experiment config
    print("Reading:"+str(config_filename))
    with open('{}.yaml'.format(config_filename)) as f:
        experiment_config = yaml.full_load(f)

    keepalive_kwargs = {
    "keepalives": 1,
    "keepalives_idle": 200,
    "keepalives_interval": 10,
    "keepalives_count": 15,
    }

    with open('database.yaml', 'r') as file:
        dbconfig = yaml.safe_load(file)


    db_url = URL(
              'postgres',
              host=dbconfig['host'],
              username=dbconfig['user'],
              database=dbconfig['db'],
              password=dbconfig['pass'],
              port=dbconfig['port'],
          )

    db_engine = create_engine(db_url, pool_pre_ping=True)


    experiment = MultiCoreExperiment(
        config=experiment_config,
        db_engine=db_engine,
        project_path=PROJECT_PATH,
        replace=replace,
        n_db_processes=4,
        n_processes=8,
        n_bigtrain_processes=1,
        save_predictions=predictions,
    )
#    experiment.validate()
    if not validate_only:
        experiment.run()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run triage pipeline')

    parser.add_argument(
        "-c",
        "--config_filename",
        type=str,
        help="Pass the config filename"
    )

    parser.add_argument("-v", "--verbose", help="Enable debug logging",
                        action="store_true")

    parser.add_argument(
        "-r",
        "--replace",
        help="If this flag is set, triage will overwrite existing models, matrices, and results",
        action="store_true"
    )
    parser.add_argument(
        "-p",
        "--predictions",
        help="If this flag is set, triage will write predictions to the database",
        action="store_true"
    )
    parser.add_argument(
        "-a",
        "--validateonly",
        help="If this flag is set, triage will only validate",
        action="store_true"
    )

    args = parser.parse_args()
    run(args.config_filename, args.verbose, args.replace, args.predictions, args.validateonly)
